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

  def reset(attributes)
    for property in getPropertyKeys
      removeProperty(property)
    end
    attributes.each_pair do |property, value|
      setProperty(property, value)
    end
  end

  # def destroy
  #   @session.neo.delete_node! @node
  #   @node = @session = nil
  # rescue NoMethodError
  #   raise StandardError.new("Node[#{@id}] does not exist anymore!")
  # end

  def to_s
    "Embedded Node[#{getId}]"
  end
end
