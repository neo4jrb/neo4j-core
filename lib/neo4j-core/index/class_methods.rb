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
        #          "Foo"  # this is used for example in multitenancy to let each domain have there own index files
        #        end
        #      end
        #   end
        #
        # @param [Neo4j::Core::Index::IndexConfig] config the configuration used as context for the config_dsl
        # @return [Neo4j::Core::Index::Indexer] The indexer that should be used to index the given class
        # @see Neo4j::Core::Index::IndexConfig for possible configuration values in the +config_dsl+ block
        # @yield evaluated in the a Neo4j::Core::Index::IndexConfig object to configure it.
        def node_indexer(config = _config || IndexConfig.new(:node), &config_dsl)
          config.instance_eval(&config_dsl)
          indexer(config)
        end

        # Sets which indexer should be used for the given relationship class
        # Same as #node_indexer except that it indexes relationships instead of nodes.
        #
        # @param (see #node_indexer)
        # @return (see #node_indexer)
        def rel_indexer(config = _config || IndexConfig.new(:rel), &config_dsl)
          config.instance_eval(&config_dsl)
          indexer(config)
        end

        def _config
          @_indexer && @_indexer.config
        end

        def indexer(index_config)
          @_indexer ||= IndexerRegistry.instance.register(Indexer.new(index_config))
        end

        # You can specify which nodes should be triggered.
        # The index can be triggered by one or more properties having one or more values.
        # This can also be done using the #node_indexer or #rel_indexer methods.
        #
        # @example trigger on property :type being 'MyType1'
        #   Neo4j::NodeIndex.trigger_on(:type => 'MyType1')
        #
        def trigger_on(hash)
          _config.trigger_on(hash)
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
