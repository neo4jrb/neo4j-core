require "neo4j-core/property_container"
# Extend the Java NodeProxy
Java::OrgNeo4jKernelImplCore::NodeProxy.class_eval do
  include Neo4j::PropertyContainer::Embedded

  def to_s
    "Embedded Node[#{getId}]"
  end

  def create_rel_to(end_node, name, attributes = {})
    return nil if get_graph_database != end_node.get_graph_database
    type = Java::OrgNeo4jGraphdb::DynamicRelationshipType.with_name(name)
    rel = create_relationship_to(end_node, type)
    if (rel.isType(type))
      rel.props = attributes
      rel
    else
      nil
    end
  end

  private
    def _destroy
      get_relationships.each { |r| r.delete }
      delete
    end
end
