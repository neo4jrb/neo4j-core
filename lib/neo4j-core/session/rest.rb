require "neography"

module Neo4j
  module Session
    class Rest
      def initialize(url = "http://localhost:7474")
        @neo = Neography::Rest.new url
      end

      # These methods make no sense for a rest server so we just return true to make our specs happy
      def always_true
        true
      end

      private :always_true
      alias :start :always_true
      alias :stop :always_true
      alias :running? :always_true
    end
  end
end