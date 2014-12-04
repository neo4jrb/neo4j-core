module Neo4j
  module Tasks

    module ConfigServer

      def config(source_text, port)
        s = set_property(source_text, 'org.neo4j.server.webserver.https.enabled', 'false')
        set_property(s, 'org.neo4j.server.webserver.port', port)
      end

      def enable_auth(source_text)
        auth_toggle(source_text, 'true')
      end

      def disable_auth(source_text)
        auth_toggle(source_text, 'false')
      end

      private

      def auth_toggle(source_text, status)
        set_property(source_text, 'dbms.security.authorization_enabled', status)
      end

      def set_property(source_text, property, value)
        source_text.gsub(/#{property}\s*=\s*(\w+)/, "#{property}=#{value}")
      end

      extend self
    end
  end
end