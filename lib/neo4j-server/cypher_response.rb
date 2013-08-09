module Neo4j::Server
  class CypherResponse
    attr_reader :data, :columns, :error_msg, :exception, :exception_fullname, :response

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
      raise "Response code #{response.code}, expected #{code} for #{response.request.path}" unless response.code == code
    end

    def set_data(data, columns)
      @data = data
      @columns = columns
      self
    end

    def set_error(error_msg, exception, exception_fullname)
      @error = true
      @error_msg = error_msg
      @exception = exception
      @exception_fullname = exception_fullname
      self
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