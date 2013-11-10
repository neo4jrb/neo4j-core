module Neo4j
  module Session
    class Rest
      def initialize(url = "http://localhost:7474")
        @neo = Neography::Rest.new url
      end

      # Start and stop make no sense for a rest server so we just return true to make our specs happy
      def start
        true
      end
      alias :stop :start
    end
  end
end