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
        @map_return_procs = map_return_procs
        @query = query
      end

      def to_s
        @query
      end

      def inspect
        "Enumerable query: '#{@query}'"
      end

      def each_no_mapping
        data.each do |row|
          hash = {}
          row.each_with_index do |row, i|
            key = columns[i].to_sym
            hash[key] = row
          end
          yield hash
        end
      end

      def each_multi_column_mapping
        data.each do |row|
          hash = {}
          row.each_with_index do |row, i|
            key = columns[i].to_sym
            proc = @map_return_procs[key]
            hash[key] = proc ? proc.call(row) : row
          end
          yield hash
        end
      end

      def each_single_column_mapping
        data.each do |row|
          result = @map_return_procs.call(row.first)
          yield result
        end
      end

      def each(&block)
        case @map_return_procs
          when NilClass then each_no_mapping &block
          when Hash then each_multi_column_mapping &block
          else each_single_column_mapping &block
        end
      end
    end

    def to_hash_enumeration(map_return_procs={}, cypher='')
      HashEnumeration.new(self, map_return_procs, cypher)
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

    def empty?
      error_status == 'EntityNotFoundException' ||
      error_msg =~ /not found/ || # Ugly that the Neo4j API gives us this error message
      (data && data.empty?)
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
