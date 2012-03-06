module Neo4j
  module Core
    module Index
      class IndexerRegistry
        def initialize
          @indexers = []
        end

        def delete_all_indexes
          @indexers.values.each { |i| i.rm_index_type }
        end

        def register(indexer)
          @indexers << indexer
          indexer
        end

        def indexers_for(props)
          Enumerable::Enumerator.new(self, :each_indexer, props)
        end

        def each_indexer(props)
          @indexers.each { |i| yield i if i.trigger_on?(props) }
        end

        def on_node_deleted(node, old_props, *)
          each_indexer(old_props) { |indexer| indexer.remove_index_on(node, old_props) }
        end

        def on_property_changed(node, field, old_val, new_val)
          each_indexer(node) { |indexer| indexer.update_index_on(node, field, old_val, new_val) }
        end

        def on_relationship_deleted(relationship, old_props, *)
          each_indexer(old_props) { |indexer| indexer.remove_index_on(relationship, old_props) }
        end

        def on_rel_property_changed(rel, field, old_val, new_val)
          each_indexer(rel) { |indexer| indexer.update_index_on(rel, field, old_val, new_val) }
        end

        def on_neo4j_shutdown(*)
          @indexers.each { |indexer| indexer.on_neo4j_shutdown }
        end

        class << self
          def instance
            @@instance ||= IndexerRegistry.new
          end
        end
      end
      Neo4j.unstarted_db.event_handler.add(IndexerRegistry.instance) unless Neo4j.read_only?
    end
  end
end