module Neo4j
  module Session
    autoload :Rest, "neo4j-core/session/rest"
    autoload :Embedded, "neo4j-core/session/embedded"
    autoload :InvalidSessionType, "neo4j-core/session/invalid_session"

    class << self
      attr_accessor :current # the current session
      
      def new(type, url)
        session = case type
          when :rest
            Rest.new(url)
          when :embedded
            Embedded.new(url)
          else
            raise InvalidSessionType
          end
          current = session unless current
          session
      end

      def running?
        if current
          current.running?
        else
          false
        end
      end

      def start
        current.start
      end

      def stop
        raise "Could not stop the current database" if !current.stop
        current = nil
      end
    end
  end
end