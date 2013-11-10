module Neo4j
  module Session
    class Rest
      def initialize(url = "http://localhost:7474")
        @neo = Neography::Rest.new url
      end

      def start
        true
      end

      alias :stop :start
    end
  end
end