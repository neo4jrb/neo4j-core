# Extend the Java NodeProxy
Java::OrgNeo4jKernelImplCore::NodeProxy.class_eval do
  # Properties
  def [](property)
    property = property.to_s
    if hasProperty(property)
      getProperty(property)
    else
      nil
    end
  end

  def []=(property, value)
    property = property.to_s
    if value.nil?
      if hasProperty(property)
        removeProperty(property)
      else
        nil
      end
    else
      setProperty(property, value)
    end
  end

  def destroy
    getRelationships.map(&:delete)
  end

  def to_s
    "Embedded Node[#{getId}]"
  end

  def create_rel_to(end_node, name, attributes = {})
    type = Java::OrgNeo4jGraphdb::DynamicRelationshipType.withName(name)
    rel = createRelationshipTo(end_node, type)
    if (rel.isType(type))
      attributes.each_pair do |key, value|
        unless value.nil?
          rel.setProperty(key, value)
        end
      end
    else
      nil
    end
  end
end
