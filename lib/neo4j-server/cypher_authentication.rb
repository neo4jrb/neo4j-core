module Neo4j
  module Server
    # Neo4j 2.2 has an authentication layer. This class provides methods for interacting with it.
    class CypherAuthentication
      class InvalidPasswordError < RuntimeError; end
      class PasswordChangeRequiredError < RuntimeError; end
      class MissingCredentialsError < RuntimeError; end

      attr_reader :connection, :url, :params, :token

      # @param [String] url_string The server address with protocol and port.
      # @param [Faraday::Connection] session_connection A Faraday::Connection object. This is either an existing object, likely the
      # same object used by the server for data, or a new one created specifically for auth tasks.
      # @param [Hash] params_hash Faraday connection options. In particularly, we're looking for basic_auth creds.
      def initialize(url_string, session_connection = new_connection, params_hash = {})
        @url = url_string
        @connection = session_connection
        @params = params_hash
      end

      # Set the username and password used to communicate with the server.
      def basic_auth(username, password)
        params[:basic_auth] ||= {}
        params[:basic_auth][:username] = username
        params[:basic_auth][:password] = password
      end

      # POSTs to the password change endpoint of the API. Does not invalidate tokens.
      # @param [String] old_password The current password.
      # @param [String] new_password The password you want to use.
      # @return [Hash] The response from the server.
      def change_password(old_password, new_password)
        connection.post("#{url}/user/neo4j/password",  'password' => old_password, 'new_password' => new_password).body
      end

      # Uses the given username and password to obtain a token, then adds the token to the connection's parameters.
      # @return [String] An access token provided by the server.
      def authenticate
        auth_response = auth_connection

        return if auth_response.status == 404 || auth_response.body.empty?

        auth_hash = if auth_response.body.is_a?(String)
                      auth_attempt if auth_response_is_auth_failed?(auth_response)
                    else
                      auth_response
                    end

        add_auth_headers(token_or_error(auth_hash)) if auth_hash.nil?
      end

      # Invalidates the existing token, which will invalidate all conncetions using this token, applies for a new token, adds this into
      # the connection headers.
      # @param [String] password The current server password.
      def reauthenticate(password)
        invalidate_token(password)
        add_auth_headers(token_or_error(auth_attempt))
      end

      # Requests a token from the authentication endpoint using the given username and password.
      # @return [Faraday::Response] The server's response, to be interpreted.
      def auth_attempt
        begin
          user = params[:basic_auth][:username]
          pass = params[:basic_auth][:password]
        rescue NoMethodError
          raise MissingCredentialsError, 'Neo4j authentication is enabled, username/password are required but missing'
        end
        connection.post("#{url}/authentication",  'username' => user, 'password' => pass)
      end

      # Takes a response object from the server and returns a token or fails with an error.
      # TODO: more error states!
      # @param [Farday::Response] auth_response The response after attempting authentication
      # @return [String] An authentication token.
      def token_or_error(auth_response)
        begin
          fail InvalidPasswordError, "Neo4j server responded with: #{auth_response.body[:errors][0][:message]}" if bad_password?(auth_response)
          fail PasswordChangeRequiredError, "Server requires a password change, please visit #{url}" if change_password?(auth_response)
        rescue NoMethodError
          raise 'Unexpected auth response, please open an issue at https://github.com/neo4jrb/neo4j-core/issues'
        end
        auth_response.body[:authorization_token]
      end

      # Invalidates tokens as described at http://neo4j.com/docs/snapshot/rest-api-security.html#rest-api-invalidating-the-authorization-token
      # @param [String] current_password The current password used to connect to the database
      def invalidate_token(current_password)
        connection.post("#{url}/user/neo4j/authorization_token",  'password' => current_password).body
      end

      # Stores an authentication token in the properly-formatted header.
      # This does not do any checking that what it has been given is a token. Whatever param is given will be base64 encoded and used as the header.
      # @param [String] token The authentication token provided by the database.
      def add_auth_headers(token)
        @token = token
        connection.headers['Authorization'] = "Basic realm=\"Neo4j\" #{token_hash(token)}"
      end

      private

      def bad_password?(auth_response)
        auth_response.status.to_i == 422
      end

      def change_password?(auth_response)
        auth_response.body[:password_change_required] == true
      end

      def auth_response_is_auth_failed?(auth_response)
        JSON.parse(auth_response.body)['errors'][0]['code'] == 'Neo.ClientError.Security.AuthorizationFailed'
      end

      # Makes testing easier, we can stub this method to simulate different responses
      def auth_connection(url = "#{@url}/authentication")
        connection.get(url)
      end

      def self.new_connection
        conn = Faraday.new do |b|
          b.request :multi_json
          b.response :multi_json, symbolize_keys: true, content_type: 'application/json'
          b.use Faraday::Adapter::NetHttpPersistent
        end
        conn.headers = {'Content-Type' => 'application/json'}
        conn
      end

      def new_connection
        self.class.new_connection
      end

      def token_hash(token)
        ::Base64.strict_encode64(":#{token}")
      end
    end
  end
end
