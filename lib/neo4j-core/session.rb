require "neo4j-core/session/rest"
require "neo4j-core/session/embedded"
require "neo4j-core/session/invalid_session"

module Neo4j
  module Session
    class << self
      attr_accessor :current # the current session
      
      def new(type, *args)
        session = case type
          when :rest
            Rest.new(*args)
          when :embedded
            Embedded.new(*args)
          else
            raise InvalidSessionTypeError.new(type)
          end
          @current = session unless @current
          session
      end

      def class
        @current.class
      end

      def running?
        if @current
          @current.running?
        else
          false
        end
      end

      def start
        if @current
          @current.start
        else
          false
        end
      end

      def stop
        raise "Could not stop the current database" if @current && !@current.stop
        @current = nil
      end
    end
  end
end