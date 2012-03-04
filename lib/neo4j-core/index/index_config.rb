module Neo4j
  module Core
    module Index

      class IndexConfig
        attr_reader :_trigger_on, :_index_names, :entity_type

        def initialize(entity_type)
          @entity_type = entity_type
          @index_type = {}
          @numeric_types = []
        end

        # DSL method
        def trigger_on(hash)
          @_trigger_on = hash
        end

        def index_names(hash)
          @_index_names = hash
        end

        def add_config(args)
          conf = args.last.kind_of?(Hash) ? args.pop : {}

          args.uniq.each do |field|
            @index_type[field.to_s] = conf[:type] || :exact
            @numeric_types << field.to_s if conf[:numeric] == true
          end
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

        def indexed?(field)
          @index_type.include?(field.to_s)
        end

        # TODO
        #def decl_type_on(field)
        #  decl_props && decl_props[field] && decl_props[field][:type]
        #end

        def numeric?(field)
          return true if @numeric_types.include?(field)
          # TODO callback to numeric dsl for Neo4j::NodeMixin decl_props check
        end

      end
    end
  end
end
