module Neo4j
  module Core
    class Label
      def labels
        get_labels.map { |x| Label.new(x.name) }
      end
    end
  end
end
