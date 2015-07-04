module Neo4j
  module Tasks
    module ConfigServer
      def config(source_text, port)
        s = set_property(source_text, 'org.neo4j.server.webserver.https.enabled', 'false')
        s = set_property(s, 'org.neo4j.server.webserver.port', port)
        set_property(s, 'org.neo4j.server.webserver.https.port', port.to_i - 1)
      end

      def set_property(source_text, property, value)
        source_text.gsub(/#{property}\s*=\s*(\w+)/, "#{property}=#{value}")
      end

      # Toggles the status of Neo4j 2.2's basic auth
      def toggle_auth(status, source_text)
        status_string = status == :enable ? 'true' : 'false'
        %w(dbms.security.authorization_enabled dbms.security.auth_enabled).each do |key|
          source_text = set_property(source_text, key, status_string)
        end
        source_text
      end

      # POSTs to an endpoint with the form required to change a Neo4j password
      # @param [String] target_address The server address, with protocol and port, against which the form should be POSTed
      # @param [String] old_password The existing password for the "neo4j" user account
      # @param [String] new_password The new password you want to use. Shocking, isn't it?
      # @return [Hash] The response from the server indicating success/failure.
      def change_password(target_address, old_password, new_password)
        uri = URI.parse("#{target_address}/user/neo4j/password")
        response = Net::HTTP.post_form(uri,  'password' => old_password, 'new_password' => new_password)
        JSON.parse(response.body)
      end

      extend self
    end
  end
end
