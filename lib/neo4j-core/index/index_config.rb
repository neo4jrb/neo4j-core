module Neo4j
  module Core
    module Index

      # Responsible for holding the configuration for one index
      # Is used in a DSL to configure the index.
      class IndexConfig
        attr_reader :_trigger_on, :_index_names, :entity_type

        def initialize(entity_type)
          @entity_type = entity_type
          @index_type = {}
          @numeric_types = []
          @_trigger_on = {}
          @decl_type = {}
        end

        # Specifies which property and values the index should be triggered on.
        # Used in the Index DSL.
        # @see Neo4j::Core::Index::ClassMethods#node_indexer
        def trigger_on(hash)
          merge_and_to_string(@_trigger_on, hash)
        end

        # Specifies the types of the properties being indexed so that the proper sort order can be applied.
        # Used in the Index DSL.
        # @see Neo4j::Core::Index::ClassMethods#node_indexer
        def decl_type(prop_and_type_hash)
          merge_and_to_string(@decl_type, prop_and_type_hash)
        end

        # Specifies an index with configuration
        # Used in the Index DSL.
        # @param [Hash] args the field and its configuration TODO
        # @see Neo4j::Core::Index::ClassMethods#index
        def index(args)
          conf = args.last.kind_of?(Hash) ? args.pop : {}

          args.uniq.each do |field|
            @index_type[field.to_s] = conf[:type] || :exact
            @numeric_types << field.to_s if conf[:numeric] == true
          end
        end

        # @return [Class] the specified type of the property or String
        # @see #decl_type
        def decl_type_on(prop)
          @decl_type[prop] || String
        end

        def trigger_on?(props)
          @_trigger_on.each_pair { |k, v| break true if props[k] == v } == true
        end

        def index_names(hash)
          @_index_names = hash
        end


        def rm_index_config
          @index_type = {}
          @numeric_types = []
        end

        def index_type(field)
          @index_type[field.to_s]
        end

        def has_index_type?(type)
          @index_type.values.include?(type)
        end

        def fields
          @index_type.keys
        end

        def index?(field)
          @index_type.include?(field.to_s)
        end

        def numeric?(field)
          return true if @numeric_types.include?(field)
          # TODO callback to numeric dsl for Neo4j::NodeMixin decl_props check
        end

        private

        def merge_and_to_string(existing_hash, new_hash)
          new_hash.each_pair { |k, v| existing_hash[k.to_s] = v }
        end
      end
    end
  end
end
