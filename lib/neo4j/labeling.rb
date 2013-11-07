# TODO remove

module Neo4j::Labeling
  def label
    @_label || self
  end

  def label_with(name)
    @_label = name
  end
end
