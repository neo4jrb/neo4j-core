module Neo4j::Server
  # Neo4j 2.2 has an authentication layer. This module provides methods that interact with that.
  module CypherAuthentication
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def authenticate(connection, url, params)
        auth_response = connection.get("#{url}/authentication")
        return nil if auth_response.body.empty?
        auth_body = JSON.parse(auth_response.body)
        token = auth_body['errors'][0]['code'] == 'Neo.ClientError.Security.AuthorizationFailed' ? obtain_token(connection, url, params) : nil
        add_auth_headers(connection, token) unless token.nil?
      end

      def obtain_token(connection, url, params)
        begin
          user = params[:basic_auth][:username]
          pass = params[:basic_auth][:password]
        rescue NoMethodError
          raise 'Neo4j authentication is enabled, username/password are required but missing'
        end
        auth_response = connection.post("#{url}/authentication", { 'username' => user, 'password' => pass })
        raise "Server requires a password change, please visit #{url}" if auth_response.body['password_change_required']
        raise "Neo4j server responded with: #{auth_response.body['errors'][0]['message']}" if auth_response.status.to_i == 422
        auth_response.body['authorization_token']
      end

      def add_auth_headers(connection, token)
        connection.headers['Authorization'] = "Basic realm=\"Neo4j\" #{token_hash(token)}"
      end

      def token_hash(token)
        Base64.strict_encode64(":#{token}")
      end

      private

      def extract_basic_auth(url, params)
        return unless url && URI(url).userinfo
        params[:basic_auth] = {
          username: URI(url).user,
          password: URI(url).password
        }
      end
    end
  end
end