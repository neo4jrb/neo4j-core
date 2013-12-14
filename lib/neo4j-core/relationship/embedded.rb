require "neo4j-core/property_container"
# Extend the Java RelationshipProxy
Java::OrgNeo4jKernelImplCore::RelationshipProxy.class_eval do
  include Neo4j::PropertyContainer::Embedded

  def type
    get_type.name
  end

  def start
    get_start_node
  end

  def end
    get_end_node
  end

  def to_s
    "Embedded Relationship[#{getId}]"
  end

  def other_node(node)
    case node
    when start
      self.end
    when self.end
        start
    else
      nil
    end
  end

  private
    def _destroy
      nodes = get_nodes
      delete
      nodes.each { |node| node.delete }
    end
end
