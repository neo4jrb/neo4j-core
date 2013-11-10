require "neography"
require "neo4j-core/session/rest"
require "neo4j-core/session/embedded"
require "neo4j-core/session/invalid_session"

module Neo4j
  module Session
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
          @current = session unless @current
      end

      def start
        @current.start
      end

      def stop
        @current.stop
      end
    end
  end
end