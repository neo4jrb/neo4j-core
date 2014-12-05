module Neo4j::Server
  # Neo4j 2.2 has an authentication layer. This class provides methods for interacting with it.
  class CypherAuthentication
    class InvalidPasswordError < RuntimeError; end
    class PasswordChangeRequiredError < RuntimeError; end
    class MissingCredentialsError < RuntimeError; end

    attr_reader :connection, :url, :params, :token

    # Creates a Faraday connection object and sets the URL used to communicate with the
    def initialize(url_string, session_connection = new_connection, params_hash = {})
      @url = url_string
      @connection = session_connection
      @params = params_hash
    end

    def basic_auth(username, password)
      params[:basic_auth] ||= {}
      params[:basic_auth][:username] = username
      params[:basic_auth][:password] = password
    end

    def change_password(old_password, new_password)
      connection.post("#{url}/user/neo4j/password", { 'password' => old_password, 'new_password' => new_password }).body
    end

    def authenticate
      auth_response = connection.get("#{url}/authentication")
      return nil if auth_response.body.empty?
      auth_body = JSON.parse(auth_response.body)
      token = auth_body['errors'][0]['code'] == 'Neo.ClientError.Security.AuthorizationFailed' ? obtain_token : nil
      add_auth_headers(token) unless token.nil?
    end

    def reauthenticate(password)
      invalidate_token(password)
      add_auth_headers(obtain_token)
    end

    def obtain_token
      begin
        user = params[:basic_auth][:username]
        pass = params[:basic_auth][:password]
      rescue NoMethodError
        raise MissingCredentialsError, 'Neo4j authentication is enabled, username/password are required but missing'
      end
      auth_response = connection.post("#{url}/authentication", { 'username' => user, 'password' => pass })
      raise PasswordChangeRequiredError, "Server requires a password change, please visit #{url}" if auth_response.body['password_change_required']
      raise InvalidPasswordError, "Neo4j server responded with: #{auth_response.body['errors'][0]['message']}" if auth_response.status.to_i == 422
      auth_response.body['authorization_token']
    end

    # Invalidates tokens as described at http://neo4j.com/docs/snapshot/rest-api-security.html#rest-api-invalidating-the-authorization-token
    # @param [String] current_password The current password used to connect to the database
    def invalidate_token(current_password)
      connection.post("#{url}/user/neo4j/authorization_token", { 'password' => current_password }).body
    end

    def add_auth_headers(token)
      @token = token
      connection.headers['Authorization'] = "Basic realm=\"Neo4j\" #{token_hash(token)}"
    end

    def new_connection
      self.class.new_connection
    end

    def self.new_connection
      conn = Faraday.new do |b|
        b.request :json
        b.response :json, :content_type => "application/json"
        b.use Faraday::Adapter::NetHttpPersistent
      end
      conn.headers = { 'Content-Type' => 'application/json' }
      conn
    end

    private

    def token_hash(token)
      Base64.strict_encode64(":#{token}")
    end
  end
end