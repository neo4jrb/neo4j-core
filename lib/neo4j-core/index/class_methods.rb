module Neo4j
  module Core
    module Index
      module ClassMethods

        # The indexer which we are delegating to
        attr_reader :_indexer


        # TODO fix YARD docs update using DSL
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
        #        trigger_on :ntype => 'foo', :name => 'bar'
        #
        #        TODO ...
        #        numeric do
        #           type = decl_props && decl_props[field.to_sym] && decl_props[field.to_sym][:type]
        #           type && !type.is_a?(String)
        #        end
        #      end
        #   end
        #
        # @example Using Neo4j::NodeMixin
        #
        #   class Contact
        #      include Neo4j::NodeMixin
        #      index :name
        #      has_one :phone
        #   end
        #
        #   class Phone
        #      include Neo4j::NodeMixin
        #      property :phone
        #      node_indexer Contact  # put index on the Contact class instead
        #      index :phone
        #   end
        #
        #   # Find an contact with a phone number, this works since they share the same index
        #   Contact.find('phone: 12345').first #=> a phone object !
        #
        # @return [Neo4j::Core::Index::Indexer] The indexer that should be used to index the given class
        def node_indexer(&config_dsl)
          # TODO reuse of index config using old index config (clazz parameter)
          indexer(IndexConfig.new(:node).instance_eval(config_dsl))
        end

        # Sets which indexer should be used for the given relationship class
        # Same as #node_indexer except that it indexes relationships instead of nodes.
        #
        # @see #node_indexer
        # @return [Neo4j::Core::Index::Indexer] The indexer that should be used to index the given class
        def rel_indexer(clazz)
          indexer(clazz, :rel)
        end


        def indexer(index_config)
          @_indexer ||= IndexerRegistry.register(Indexer.new(index_config))
        end


        class << self
          private


          # @macro [attach] index.delegate
          #   @method $1(*args, &block)
          #   Sends the `$1` message to @_indexer instance with the supplied parameters.
          #   @see Neo4j::Core::Index::Indexer#$1
          def delegate(method_name)
            class_eval(<<-EOM, __FILE__, __LINE__)
              def #{method_name}(*args, &block)
                @_indexer.send(:#{method_name}, *args, &block)
              end
            EOM
          end

        end

        delegate :index
        delegate :find
        delegate :index?
        delegate :index_type?
        delegate :rm_index_type
        delegate :rm_index_config
        delegate :add_index
        delegate :rm_index
        delegate :index_type_for
        delegate :index_names
        delegate :index_types

      end


    end
  end
end
