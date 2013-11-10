require "neography"

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

    class Rest
      def initialize(url = "http://localhost:7474")
        @neo = Neography::Rest.new url
      end

      def start
        true
      end

      alias :stop :start
    end

    class Embedded
      def initialize(path)
      end
    end

    class InvalidSessionType < StandardError
    end
  end
end