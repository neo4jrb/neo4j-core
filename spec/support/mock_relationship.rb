class MockRelationship
end

Neo4j::Relationship.extend_java_class(MockRelationship)

class MockRelationship
  def initialize(type, start_node, end_node)
    @@id_counter ||= 0
    @@id_counter += 1
    @id = @@id_counter
    @type = type
    @start_node = start_node
    @end_node = end_node
  end

  def _end_node
    @end_node
  end

  def _start_node
    @start_node
  end

  def getId
    @id
  end

  def get_other_node(not_this)
    not_this == _start_node ? _end_node : _start_node
  end

  def kind_of?(other)
    other == Java::OrgNeo4jGraphdb::Relationship || super
  end
end

