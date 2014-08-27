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
          yield(row.each_with_index.each_with_object(struct.new) do |(value, i), result|
            result[columns[i].to_sym] = value
          end)
        end
      end
    end

    def to_struct_enumeration(cypher = '')
      HashEnumeration.new(self, cypher)
    end

    def to_node_enumeration(cypher = '', session = Neo4j::Session.current)
      Enumerator.new do |yielder|
        self.to_struct_enumeration(cypher).each do |row|
          yielder << row.each_pair.each_with_object(@struct.new) do |(column, value), result|
            result[column] = map_row_value(value, session)
          end
        end
      end
    end

    def map_row_value(value, session)
      if value.is_a?(Hash)
        if value['labels']
          add_entity_id(value)
          CypherNode.new(session, value).wrapper
        elsif value['type']
          add_entity_id(value)
          CypherRelationship.new(session, value).wrapper
        else
          value
        end
      elsif value.is_a?(Array)
        value.map {|v| map_row_value(v, session) }
      else
        value
      end
    end

    attr_reader :struct
    
    def initialize(response, uncommited = false)
      @response = response
      @uncommited = uncommited
    end


    def entity_data(id=nil)
      if uncommited?
        data = @data.first['row'].first
        data.is_a?(Hash) ? {'data' => data, 'id' => id} : data
      else
        data = @data[0][0]
        data.is_a?(Hash) ? add_entity_id(data) : data
      end
    end

    def first_data(id = nil)
      if uncommited?
        data = @data.first['row'].first
        #data.is_a?(Hash) ? {'data' => data, 'id' => id} : data
      else
        data = @data[0][0]
        data.is_a?(Hash) ? add_entity_id(data) : data
      end
    end

    def add_entity_id(data)
      data.merge!({'id' => data['self'].split('/')[-1].to_i})
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

    def each_data_row
      if uncommited?
        data.each{|r| yield r['row']}
      else
        data.each{|r| yield r}
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
      raise "Tried to raise error without an error" unless @error
      raise ResponseError.new(@error_msg, @error_status, @error_code)
    end

    def raise_cypher_error
      raise "Tried to raise error without an error" unless @error
      raise Neo4j::Session::CypherError.new(@error_msg, @error_code, @error_status)
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
