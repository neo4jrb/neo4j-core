module Neo4j
  module Core
    module Index
      module ClassMethods

        # The indexer which we are delegating to
        attr_reader :_indexer


        # Sets which indexer should be used for the given node class.
        # You can share an indexer between several different classes.
        #
        # @example Using custom index
        #
        #   class MyIndex
        #      extend Neo4j::Core::Index::ClassMethods
        #      include Neo4j::Core::Index
        #
        #      node_indexer do
        #        index_names :exact => 'myindex_exact', :fulltext => 'myindex_fulltext'
        #        trigger_on :ntype => 'foo', :name => ['bar', 'foobar']
        #
        #        prefix_index_name do
        #          return "" unless Neo4j.running?
        #          return "" unless @indexer_for.respond_to?(:ref_node_for_class)
        #          ref_node = @indexer_for.ref_node_for_class.wrapper
        #          prefix = ref_node.send(:_index_prefix) if ref_node.respond_to?(:_index_prefix)
        #          prefix ||= ref_node[:name] # To maintain backward compatiblity
        #          prefix.blank? ? "" : prefix + "_"
        #         end
        #
        #
        #        numeric do
        #           type = decl_props && decl_props[field.to_sym] && decl_props[field.to_sym][:type]
        #           type && !type.is_a?(String)
        #        end
        #      end
        #   end
        #
        # @param [Neo4j::Core::Index::IndexConfig] config the configuration used as context for the config_dsl
        # @return [Neo4j::Core::Index::Indexer] The indexer that should be used to index the given class
        # @see Neo4j::Core::Index::IndexConfig for possible configuration values in the +config_dsl+ block
        # @yield evaluated in the a Neo4j::Core::Index::IndexConfig object to configure it.
        def node_indexer(config = IndexConfig.new(:node), &config_dsl)
          config.instance_eval(&config_dsl)
          indexer(config)
        end

        # Sets which indexer should be used for the given relationship class
        # Same as #node_indexer except that it indexes relationships instead of nodes.
        #
        # @param (see #node_indexer)
        # @return (see #node_indexer)
        def rel_indexer(config = IndexConfig.new(:rel), &config_dsl)
          config.instance_eval(&config_dsl)
          indexer(config)
        end


        def indexer(index_config)
          @_indexer ||= IndexerRegistry.instance.register(Indexer.new(index_config))
        end


        class << self
          private


          # @macro [attach] index.delegate
          #   @method $1(*args, &block)
          #   Delegates the `$1` message to @_indexer instance with the supplied parameters.
          #   @see Neo4j::Core::Index::Indexer#$1
          def delegate(method_name)
            class_eval(<<-EOM, __FILE__, __LINE__)
              def #{method_name}(*args, &block)
                _indexer.send(:#{method_name}, *args, &block)
              end
            EOM
          end

        end

        delegate :index
        delegate :find
        delegate :index?
        delegate :has_index_type?
        delegate :rm_index_type
        delegate :rm_index_config
        delegate :add_index
        delegate :rm_index
        delegate :index_type
        delegate :index_name_for_type
      end


    end
  end
end
