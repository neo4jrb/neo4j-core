class MockNode
  def initialize
    @@id_counter ||= 0
    @@id_counter += 1
    @id = @@id_counter
  end

  def getId
    @id
  end

  def kind_of?(other)
    other == Java::OrgNeo4jGraphdb::Node || super
  end
end

Neo4j::Node.extend_java_class(MockNode)
