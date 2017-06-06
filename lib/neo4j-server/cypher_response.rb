module Neo4j
  module Server
    class CypherResponse
      attr_reader :data, :columns, :error_msg, :error_status, :error_code, :response

      class ResponseError < StandardError
        attr_reader :status, :code

        def initialize(msg, status, code)
          super(msg)
          @status = status
          @code = code
        end
      end

      class ConstraintViolationError < ResponseError; end

      class HashEnumeration
        include Enumerable
        extend Forwardable
        def_delegator :@response, :error_msg
        def_delegator :@response, :error_status
        def_delegator :@response, :error_code
        def_delegator :@response, :columns
        def_delegator :@response, :struct

        def initialize(response, query)
          @response = response
          @query = query
        end

        def to_s
          @query
        end

        def inspect
          "Enumerable query: '#{@query}'"
        end

        def each
          @response.each_data_row { |row| yield struct_rows(row) }
        end

        def struct_rows(row)
          struct.new.tap do |result|
            row.each_with_index { |value, i| result[columns[i]] = value }
          end
        end
      end

      EMPTY_STRING = ''
      def to_struct_enumeration(cypher = EMPTY_STRING)
        HashEnumeration.new(self, cypher)
      end

      def to_node_enumeration(cypher = EMPTY_STRING, session = Neo4j::Session.current)
        Enumerator.new do |yielder|
          to_struct_enumeration(cypher).each do |row|
            yielder << row_pair_in_struct(row, session)
          end
        end
      end

      def row_pair_in_struct(row, session)
        @struct.new.tap do |result|
          row.each_pair do |column, value|
            result[column] = map_row_value(value, session)
          end
        end
      end

      def map_row_value(value, session)
        if value.is_a?(Hash) && looks_like_an_object?(value)
          hash_value_as_object(value, session)
        elsif value.is_a?(Array)
          value.map! { |v| map_row_value(v, session) }
        else
          value
        end
      end

      def hash_value_as_object(value, session)
        return value unless %i[node relationship].include?(identify_entity(value))
        add_entity_id(value)

        basic_obj = (node?(value) ? CypherNode : CypherRelationship).new(session, value)
        unwrapped? ? basic_obj : basic_obj.wrapper
      end

      def identify_entity(data)
        self_string = data[:self]
        if self_string
          if self_string.include?('node')
            :node
          elsif self_string.include?('relationship')
            :relationship
          end
        elsif %i[nodes relationships start end length].all? { |k| data.key?(k) }
          :path
        end
      end

      def looks_like_an_object?(value)
        value[:labels] || value[:type]
      end

      def unwrapped!
        @_unwrapped_obj = true
      end

      def unwrapped?
        !!@_unwrapped_obj
      end

      def node?(value)
        value[:labels]
      end

      attr_reader :struct

      def initialize(response, uncommited = false)
        @response = response
        @uncommited = uncommited
      end

      def entity_data(id = nil)
        if @uncommited
          data = @data.first[:row].first
          data.is_a?(Hash) ? {data: data, id: id} : data
        else
          data = @data[0][0]
          data.is_a?(Hash) ? add_entity_id(data) : data
        end
      end

      def first_data
        if @uncommited
          @data.first[:row].first
        else
          data = @data[0][0]
          data.is_a?(Hash) ? add_entity_id(data) : data
        end
      end

      def add_entity_id(data)
        data[:id] = if data[:metadata] && data[:metadata][:id]
                      data[:metadata][:id]
                    else
                      data[:self].split('/')[-1].to_i
                    end
        data
      end

      def error?
        !!@error
      end

      def raise_if_cypher_error!
        raise_cypher_error if error?
      end

      RETRYABLE_ERROR_STATUSES = %w[DeadlockDetectedException AcquireLockTimeoutException ExternalResourceFailureException UnknownFailureException]
      def retryable_error?
        return unless error?
        RETRYABLE_ERROR_STATUSES.include?(@error_status)
      end

      def data?
        !response.body[:data].nil?
      end

      def raise_unless_response_code(code)
        fail "Response code #{response.status}, expected #{code} for #{response.headers[:location]}, #{response.body}" unless response.status == code
      end

      def each_data_row
        data.each do |r|
          yieldable = if @uncommitted
                        r[:row]
                      else
                        transaction_row?(r) ? r[:rest] : r
                      end
          yield yieldable
        end
      end

      def transaction_response?
        response.respond_to?(:body) && !response.body[:commit].nil?
      end

      def set_data(response)
        @data = response[:data]
        @columns = response[:columns]
        @struct = @columns.empty? ? Object.new : Struct.new(*@columns.map(&:to_sym))
        self
      end

      def set_error(error)
        @error = true
        @error_msg = error[:message]
        @error_status = error[:status] || error[:exception] || error[:code]
        @error_code = error[:code] || error[:fullname]
        self
      end

      CONSTRAINT_ERROR = 'Neo.ClientError.Schema.ConstraintViolation'
      def raise_error
        fail 'Tried to raise error without an error' unless @error
        error_class = constraint_error? ? ConstraintViolationError : ResponseError
        fail error_class.new(@error_msg, @error_status, @error_code)
      end

      def constraint_error?
        @error_code == CONSTRAINT_ERROR || (@error_msg || '').include?('already exists with')
      end

      def raise_cypher_error
        fail 'Tried to raise error without an error' unless @error
        fail Neo4j::Session::CypherError.new(@error_msg, @error_code, @error_status)
      end


      def self.create_with_no_tx(response)
        case response.status
        when 200 then new(response).set_data(response.body)
        when 400 then new(response).set_error(response.body)
        else
          fail "Unknown response code #{response.status} for #{response.env[:url]}"
        end
      end

      def self.create_with_tx(response)
        fail "Unknown response code #{response.status} for #{response.request_uri}" unless response.status == 200

        new(response, true).tap do |cr|
          body = response.body
          body[:errors].empty? ? cr.set_data(body[:results].first) : cr.set_error(body[:errors].first)
        end
      end

      private

      def transaction_row?(row)
        row.is_a?(Hash) && row[:rest] && row[:row]
      end
    end
  end
end
