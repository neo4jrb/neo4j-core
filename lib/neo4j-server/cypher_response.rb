module Neo4j::Server
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
      def_delegator :@response, :data
      def_delegator :@response, :columns

      def initialize(response, map_return_procs, query)
        @response = response
        @map_return_procs = map_return_procs || {}
        @query = query
      end

      def to_s
        @query
      end

      def inspect
        "Enumerable query: '#{@query}'"
      end

      def multi_column_mapping(row)
        row.each_with_index.each_with_object({}) do |(row, i), hash|
          key = columns[i].to_sym
          proc = @map_return_procs[key]
          hash[key] = proc ? proc.call(row) : row
        end
      end

      def single_column_mapping(row)
        @map_return_procs.call(row.first)
      end

      def each(&block)
        method = @map_return_procs.is_a?(Hash) ? :multi_column_mapping : :single_column_mapping

        data.each do |row|
          yield self.send(method, row)
        end
      end
    end

    def to_hash_enumeration(map_return_procs = {}, cypher = '')
      HashEnumeration.new(self, map_return_procs, cypher)
    end

    def to_node_enumeration(cypher = '', session = Neo4j::Session.current)
      Enumerator.new do |yielder|
        self.to_hash_enumeration({}, cypher).each do |row|
          yielder << row.each_with_object({}) do |(column, value), result|
            result[column] = if value.is_a?(Hash)
              if value['labels']
                CypherNode.new(session, value).wrapper
              elsif value['type']
                CypherRelationship.new(session, value).wrapper
              else
                raise "Invalid response data: #{value.inspect}"
              end
            else
              value
            end
          end
        end
      end
    end

    def initialize(response, uncommited = false)
      @response = response
      @uncommited = uncommited
    end


    def first_data
      if uncommited?
        @data.first['row'].first
      else
        @data[0][0]
      end
    end

    def error?
      !!@error
    end

    def uncommited?
      @uncommited
    end

    def raise_unless_response_code(code)
      raise "Response code #{response.code}, expected #{code} for #{response.request.path}, #{response.body}" unless response.code == code
    end

    def set_data(data, columns)
      @data = data
      @columns = columns
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
      raise "Tried to raise error without an error" unless @error
      raise ResponseError.new(@error_msg, @error_status, @error_code)
    end

    def self.create_with_no_tx(response)
      case response.code
        when 200
          CypherResponse.new(response).set_data(response['data'], response['columns'])
        when 400
          CypherResponse.new(response).set_error(response['message'], response['exception'], response['fullname'])
        else
          raise "Unknown response code #{response.code} for #{response.request.path.to_s}"
      end
    end

    def self.create_with_tx(response)
      raise "Unknown response code #{response.code} for #{response.request.path.to_s}" unless response.code == 200

      first_result = response['results'][0]
      cr = CypherResponse.new(response, true)

      if (response['errors'].empty?)
        cr.set_data(first_result['data'], first_result['columns'])
      else
        first_error = response['errors'].first
        cr.set_error(first_error['message'], first_error['status'], first_error['code'])
      end
      cr
    end
  end
end
