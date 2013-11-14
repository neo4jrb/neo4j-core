module Neo4j
  class Label
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end
end