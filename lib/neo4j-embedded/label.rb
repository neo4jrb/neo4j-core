module Neo4j
  class Label
    class << self
      def indexes
        schema_query(:get_indexes)
      end

      def constraints
        schema_query(:get_constraints)
      end

      def index?(label, property)
        schema_index_operation(label, property, :indexes)
      end

      def constraint?(label, property)
        schema_index_operation(label, property, :constraints)
      end

      def drop_all_indexes
        Neo4j::Transaction.run do
          schema.get_indexes.to_a.each do |i|
            begin
              i.drop
            rescue Java::JavaLang::IllegalStateException
            end
          end
        end
      end

      def drop_all_constraints
        Neo4j::Transaction.run do
          schema.get_constraints.to_a.each(&:drop)
        end
      end

      private

      def schema_query(query_method)
        [].tap do |index_array|
          Neo4j::Transaction.run do
            schema.send(query_method).to_a.each { |i| index_array << index_hash(i) }
          end
        end
      end

      def schema_index_operation(label, property, schema_method)
        label = label.to_s
        property = property.to_s
        !send(schema_method).select { |i| matched_index(i, label, property) }.empty?
      end

      def index_hash(java_index)
        {property_keys: java_index.get_property_keys.to_a, label: java_index.get_label.name}
      end

      def matched_index(java_index, label, property)
        java_index[:property_keys].first == property && java_index[:label] == label
      end

      def schema
        Neo4j::Session.current.graph_db.schema
      end
    end
  end
end
