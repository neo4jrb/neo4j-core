# Extend the Java NodeProxy
Java::OrgNeo4jKernelImplCore::NodeProxy.class_eval do
  # Properties
  def [](*keys)
    keys.map!(&:to_s)
    result = []
    keys.each do |k|
      result << if has_property(k)
        get_property(k)
      else
        nil
      end
    end
    if keys.length == 1
      result.first
    else
      result
    end
  end

  def []=(*keys, values)
    values = [values].flatten
    keys.map!(&:to_s)
    attributes = Hash[keys.zip values]
    nil_values = lambda { |_, v| v.nil? }
    keys_to_delete = attributes.select(&nil_values).keys
    attributes.delete_if(&nil_values)
    keys_to_delete.each { |k| remove_property(k) if has_property(k) }
    attributes.each { |k, v| set_property(k, v) }
  end

  def props
    result = {}
    get_property_keys.each do |key|
      result[key] = get_property(key)
    end
    result
  end

  def props=(attributes)
    get_property_keys.each { |key| remove_property(key) }
    attributes = attributes.delete_if { |_, value| value.nil? }
    attributes.each { |key, value| set_property(key, value) }
  end

  def destroy
    get_relationships.map(&:delete)
  end

  def to_s
    "Embedded Node[#{getId}]"
  end

  def create_rel_to(end_node, name, attributes = {})
    type = Java::OrgNeo4jGraphdb::DynamicRelationshipType.with_name(name)
    rel = create_relationship_to(end_node, type)
    if (rel.isType(type))
      attributes.each_pair do |key, value|
        unless value.nil?
          rel.set_property(key, value)
        end
      end
    else
      nil
    end
  end
end
