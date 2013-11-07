module Neo4j
  module EntityEquality
    def ==(o)
      o.class == self.class && o.neo_id == neo_id
    end
    alias_method :eql?, :==

  end
end