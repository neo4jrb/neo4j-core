module Neo4j
  module Core
    module Index
      module ClassMethods
        attr_reader :_indexer


        # Sets which indexer should be used for the given node class.
        # You can share an indexer between several different classes.
        #
        # ==== Example
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
        # ==== Returns
        # The indexer that should be used to index the given class
        def node_indexer(clazz)
          indexer(clazz, :node)
        end

        # Sets which indexer should be used for the given relationship class
        # Same as #node_indexer except that it indexes relationships instead of nodes.
        #
        def rel_indexer(clazz)
          indexer(clazz, :rel)
        end

        def indexer(clazz, type) #:nodoc:
          @_indexer ||= IndexerRegistry.create_for(self, clazz, type)
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
        delegate :delete_index_type
        delegate :rm_field_type
        delegate :add_index
        delegate :rm_index
        delegate :index_type_for
        delegate :index_names
        delegate :index_types

      end


    end
  end
end
