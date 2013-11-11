# Extend the Java NodeProxy
Java::OrgNeo4jKernelImplCore::NodeProxy.class_eval do
  def method_missing(get_or_set_property, *args)
    if match_data = /\A(\w+)\Z/.match(get_or_set_property)
      property = match_data[0]
      getProperty(property)
    elsif match_data = /\A(\w+=)\Z/.match(get_or_set_property)
      assert args.count == 1, "Syntax error"
      property = match_data[0]
      value = args[0]
      setProperty(property, value)
    else
      super
    end
  end
end
