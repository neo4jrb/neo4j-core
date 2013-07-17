class MockRelationship
end

Neo4j::Relationship.extend_java_class(MockRelationship)

class MockRelationship
  attr_reader :rel_type
  include Neo4j::Core::Property::Java

  def initialize(type=:friends, start_node=MockNode.new, end_node=MockNode.new)
    @@id_counter ||= 0
    @@id_counter += 1
    @id = @@id_counter
    @rel_type = type
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

  alias_method :getEndNode, :_end_node
  alias_method :getStartNode, :_start_node
  alias_method :getType, :rel_type

end

Neo4j::Relationship.extend_java_class(MockRelationship)
