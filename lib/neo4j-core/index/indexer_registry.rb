module Neo4j
  module Core
    module Index
      class IndexerRegistry
        def initialize
          @indexers = {}
        end

        def delete_all_indexes
          @indexers.values.each {|i| i.rm_index_type}
        end

        def register(indexer)
          @indexers   ||= {}
          index_config = indexer.config
          # TODO INHERIT index config
#          index.inherit_fields_from(@indexers[using_other_clazz.to_s]) if @indexers[using_other_clazz.to_s]
          index_config._trigger_on.each_pair do |k,v|
            @indexers[k.to_s] ||= {}
            @indexers[k.to_s][v.to_s] ||= []
            @indexers[k.to_s][v.to_s] << indexer
          end
        end

        def indexers_for(props)
          Enumerable::Enumerator.new(self, :each_indexer, props)
        end

        def each_indexer(props)
          @indexers.keys.each do |index_key|
            value = props[index_key]
            next unless value
            indexers = @indexers[index_key][value]
            indexers && indexers.each {|indexer| yield indexer}
          end
        end

        def on_node_deleted(node, old_props, deleted_relationship_set, _)
          each_indexer(old_props) {|indexer| indexer.remove_index_on_fields(node, old_props, deleted_relationship_set) }
        end

        def on_property_changed(node, field, old_val, new_val)
          each_indexer(node) { indexer.update_index_on(node, field, old_val, new_val) }
        end

        def on_rel_property_changed(rel, field, old_val, new_val)
          # works exactly like for nodes
          on_property_changed(rel, field, old_val, new_val)
        end

        def on_relationship_created(rel,created_identity_map)
          end_node = rel._end_node
          # if end_node was created in this transaction then it will be handled in on_property_changed
          created = created_identity_map.get(end_node.neo_id)
          each_indexer(end_node) { |indexer| indexer.update_on_new_relationship(rel)} unless created
        end

        def on_relationship_deleted(rel, old_props, deleted_relationship_set, deleted_identity_map)
          on_node_deleted(rel, old_props, deleted_relationship_set, deleted_identity_map)
          # if only the relationship has been deleted then we have to remove the index
          # if both the relationship and the node has been deleted then the index will be removed in the
          # on_node_deleted callback
          end_node = rel._end_node
          deleted = deleted_identity_map.get(end_node.neo_id)
          each_indexer(rel){|indexer| indexer.update_on_deleted_relationship(rel)} unless deleted
        end

        def on_neo4j_shutdown(*)
          @indexers.each_value {|indexer| indexer.on_neo4j_shutdown}
        end

        class << self
          def instance
            @@instance ||= IndexerRegistry.new
          end
        end
      end
      Neo4j.unstarted_db.event_handler.add(IndexerRegistry) unless Neo4j.read_only?
    end
end
end