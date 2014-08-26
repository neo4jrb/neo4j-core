module Neo4j
  module Tasks

    module ConfigServer

      def config(data, port)
        s = set_property(data, 'org.neo4j.server.webserver.https.enabled', 'false')
        set_property(s, 'org.neo4j.server.webserver.port', port)
      end

      def set_property(data, property, value)
        data.gsub(/#{property}\s*=\s*(\w+)/, "#{property}=#{value}")
      end

      extend self
    end
  end
end