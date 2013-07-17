module Neo4j::Core
  module Label
    def labels
      get_labels.map{|x| Label.new(x.name) }
    end
  end

end