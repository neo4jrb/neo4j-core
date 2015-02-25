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

        def each(&block)
          @response.each_data_row do |row|
            yield struct_rows(row)
          end
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
          @result_index = 0
          to_struct_enumeration(cypher).each do |row|
            @row_index = 0
            yielder << row_pair_in_struct(row, session)
            @result_index += 1
          end
        end
      end

      def row_pair_in_struct(row, session)
        @struct.new.tap do |result|
          row.each_pair do |column, value|
            result[column] = map_row_value(value, session)
            @row_index += 1
          end
        end
      end

      def map_row_value(value, session)
        if value.is_a?(Hash)
          hash_value_as_object(value, session)
        elsif value.is_a?(Array)
          value.map! { |v| map_row_value(v, session) }
        else
          value
        end
      end

      def hash_value_as_object(value, session)
        data =  case
                when transaction_response?
                  add_transaction_entity_id
                  mapped_rest_data
                when value[:labels] || value[:type]
                  add_entity_id(value)
                  value
                else
                  return value
                end
        (node?(value) ? CypherNode : CypherRelationship).new(session, data).wrapper
      end

      def node?(value)
        transaction_response? ? !mapped_rest_data[:start] : value[:labels]
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
          # data.is_a?(Hash) ? {'data' => data, 'id' => id} : data
        else
          data = @data[0][0]
          data.is_a?(Hash) ? add_entity_id(data) : data
        end
      end

      def add_entity_id(data)
        data[:id] = if data[:metadata] && data[:metadata][:id]
                      data[:metadata][:id]
                    else
                      self.class.id_from_url(data[:self])
                    end
        data
      end

      def add_transaction_entity_id
        mapped_rest_data[:id] = mapped_rest_data[:self].split('/').last.to_i
        mapped_rest_data
      end

      def error?
        !!@error
      end

      RETRYABLE_ERROR_STATUSES = %w(DeadlockDetectedException AcquireLockTimeoutException ExternalResourceFailureException UnknownFailureException)
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
        if @uncommited
          data.each { |r| yield r[:row] }
        else
          data.each { |r| yield r }
        end
      end

      def set_data(data, columns)
        @data = data
        @columns = columns
        @struct = columns.empty? ? Object.new : Struct.new(*columns.map(&:to_sym))
        self
      end

      def set_error(error_msg, error_status, error_core)
        @error = true
        @error_msg = error_msg
        @error_status = error_status
        @error_code = error_core
        self
      end

      def raise_error
        fail 'Tried to raise error without an error' unless @error
        fail ResponseError.new(@error_msg, @error_status, @error_code)
      end

      def raise_cypher_error
        fail 'Tried to raise error without an error' unless @error
        fail Neo4j::Session::CypherError.new(@error_msg, @error_code, @error_status)
      end


      def self.create_with_no_tx(response)
        case response.status
        when 200
          CypherResponse.new(response).set_data(response.body[:data], response.body[:columns])
        when 400
          CypherResponse.new(response).set_error(response.body[:message], response.body[:exception], response.body[:fullname])
        else
          fail "Unknown response code #{response.status} for #{response.env[:url]}"
        end
      end

      def self.create_with_tx(response)
        fail "Unknown response code #{response.status} for #{response.request_uri}" unless response.status == 200

        first_result = response.body[:results][0]
        cr = CypherResponse.new(response, true)

        if response.body[:errors].empty?
          cr.set_data(first_result[:data], first_result[:columns])
        else
          first_error = response.body[:errors].first
          cr.set_error(first_error[:message], first_error[:status], first_error[:code])
        end
        cr
      end

      def transaction_response?
        response.respond_to?(:body) && !response.body[:commit].nil?
      end

      def rest_data
        @result_index = @row_index = 0
        mapped_rest_data
      end

      def rest_data_with_id
        rest_data[:id] = mapped_rest_data[:self].split('/').last.to_i
        rest_data
      end

      class << self
        def id_from_url(url)
          url.split('/')[-1].to_i
        end
      end

      private

      attr_reader :row_index

      attr_reader :result_index

      def mapped_rest_data
        response.body[:results][0][:data][result_index][:rest][row_index]
      end
    end
  end
end
