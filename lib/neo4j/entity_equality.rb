module Neo4j
  module EntityEquality
    def ==(other)
      other.class == self.class && other.neo_id == neo_id
    end
    alias eql? ==
  end
end
