module Neo4j
  module Core
    module Index

      class IndexConfig
        def initialize(indexer_for)
          @indexer_for = indexer_for
          @index_type = {}
          @numeric_types = []
        end

        def add_config(args)
          conf = args.last.kind_of?(Hash) ? args.pop : {}

          args.uniq.each do |field|
            @index_type[field.to_s] = conf[:type] || :exact
            @numeric_types << field.to_s if conf[:numeric] == true
          end
        end

        def decl_props
          @index_config ||= @indexer_for.respond_to?(:_decl_props) && @indexer_for._decl_props
        end

        def rm_index_config
          @index_type = {}
          @numeric_types = []
        end

        def index_type(field)
          @index_type[field.to_s]
        end

        def decl_type_on(field)
          decl_props && decl_props[field] && decl_props[field][:type]
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

        def numeric?(field)
          return true if @numeric_types.include?(field)
          type = decl_props && decl_props[field.to_sym] && decl_props[field.to_sym][:type]
          type && !type.is_a?(String)
        end

      end
    end
  end
end
