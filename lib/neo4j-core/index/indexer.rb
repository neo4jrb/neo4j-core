module Neo4j
  module Core
    module Index

      # This class is delegated from the Neo4j::Core::Index::ClassMethod
      # @see Neo4j::Core::Index::ClassMethods
      class Indexer
        # @return [Neo4j::Core::Index::IndexConfig]
        attr_reader :config
        attr_reader :parent_indexers

        def initialize(config)
          @config = config
          @indexes = {} # key = type, value = java neo4j index
          # to enable subclass indexing to work properly, store a list of parent indexers and
          # whenever an operation is performed on this one, perform it on all
          @parent_indexers = []
        end


        def to_s
          "Indexer @#{object_id} [index on #{@config.fields.join(', ')}]"
        end

        # Add an index on a field so that it will be automatically updated by neo4j transactional events.
        #
        # The index method takes an optional configuration hash which allows you to:
        #
        # @example Add an index on an a property
        #
        #   class Person
        #     include Neo4j::NodeMixin
        #     index :name
        #   end
        #
        # When the property name is changed/deleted or the node created it will keep the lucene index in sync.
        # You can then perform a lucene query like this: Person.find('name: andreas')
        #
        # @example Add index on other nodes.
        #
        #   class Person
        #     include Neo4j::NodeMixin
        #     has_n(:friends).to(Contact)
        #     has_n(:known_by).from(:friends)
        #     index :user_id, :via => :known_by
        #   end
        #
        # Notice that you *must* specify an incoming relationship with the via key, as shown above.
        # In the example above an index <tt>user_id</tt> will be added to all Person nodes which has a <tt>friends</tt> relationship
        # that person with that user_id. This allows you to do lucene queries on your friends properties.
        #
        # @example Set the type value to index
        #
        #   class Person
        #     include Neo4j::NodeMixin
        #     property :height, :weight, :type => Float
        #     index :height, :weight
        #   end
        #
        # By default all values will be indexed as Strings.
        # If you want for example to do a numerical range query you must tell Neo4j.rb to index it as a numeric value.
        # You do that with the key <tt>type</tt> on the property.
        #
        # Supported values for <tt>:type</tt> is <tt>String</tt>, <tt>Float</tt>, <tt>Date</tt>, <tt>DateTime</tt> and <tt>Fixnum</tt>
        #
        # === For more information
        #
        # @see Neo4j::Core::Index::LuceneQuery
        # @see #find
        #
        def index(*args)
          @config.index(args)
        end

        # @return [true,false] if there is an index on the given field.
        def index?(field)
          @config.index?(field)
        end

        # @return [true,false] if the
        def trigger_on?(props)
          @config.trigger_on?(props)
        end

        # @return [Symbol] the type of index for the given field (e.g. :exact or :fulltext)
        def index_type(field)
          @config.index_type(field)
        end

        # @return [true,false]  if there is an index of the given type defined.
        def has_index_type?(type)
          @config.has_index_type?(type)
        end

        # Adds an index on the given entity
        # This is normally not needed since you can instead declare an index which will automatically keep
        # the lucene index in sync. See #index
        def add_index(entity, field, value)
          return false unless index?(field)
          conv_value = indexed_value_for(field, value)
          index = index_for_field(field.to_s)
          index.add(entity, field, conv_value)
          @parent_indexers.each { |i| i.add_index(entity, field, value) }
        end


        # Removes an index on the given entity
        # This is normally not needed since you can instead declare an index which will automatically keep
        # the lucene index in sync. See #index
        def rm_index(entity, field, value)
          return false unless index?(field)
          index_for_field(field).remove(entity, field, value)
          @parent_indexers.each { |i| i.rm_index(entity, field, value) }
        end

        # Performs a Lucene Query.
        #
        # In order to use this you have to declare an index on the fields first, see #index.
        # Notice that you should close the lucene query after the query has been executed.
        # You can do that either by provide an block or calling the Neo4j::Core::Index::LuceneQuery#close
        # method. When performing queries from Ruby on Rails you do not need this since it will be automatically closed
        # (by Rack).
        #
        # @example with a block
        #
        #   Person.find('name: kalle') {|query| puts "#{[*query].join(', )"}
        #
        # @example
        #
        #   query = Person.find('name: kalle')
        #   puts "First item #{query.first}"
        #   query.close
        #
        # @return [Neo4j::Core::Index::LuceneQuery] a query object
        def find(query, params = {})
          index = index_for_type(params[:type] || :exact)
          if query.is_a?(Hash) && (query.include?(:conditions) || query.include?(:sort))
            params.merge! query.reject{|k,_| k == :conditions}
            query.delete(:sort)
            query = query.delete(:conditions) if query.include?(:conditions)
          end
          query = (params[:wrapped].nil? || params[:wrapped]) ? LuceneQuery.new(index, @config, query, params) : index.query(query)

          if block_given?
            begin
              ret = yield query
            ensure
              query.close
            end
            ret
          else
            query
          end
        end

        # Delete all index configuration. No more automatic indexing will be performed
        def rm_index_config
          @config.rm_index_config
        end

        # delete the index, if no type is provided clear all types of indexes
        def rm_index_type(type=nil)
          if type
            key = index_key(type)
            @indexes[key] && @indexes[key].delete
            @indexes[key] = nil
          else
            @indexes.each_value { |index| index.delete }
            @indexes.clear
          end
        end

        # Specifies the location on the filesystem of the lucene index for the given index type.
        #
        # If not specified it will have the default location:
        #
        #   Neo4j.config[:storage_path]/index/lucene/node|relationship/ParentModuleName_SubModuleName_ClassName-indextype
        #
        # @example
        #
        #  module Foo
        #    class Person
        #       include Neo4j::NodeMixin
        #       index :name
        #       index_names[:fulltext] = 'my_location'
        #    end
        #  end
        #
        #  Person.index_names[:fulltext] => 'my_location'
        #  Person.index_names[:exact] => 'Foo_Person-exact' # default Location
        #
        # The index can be prefixed, see Neo4j#threadlocal_ref_node= and multi dependency.
        #
        def index_names
          @index_names ||= Hash.new do |hash, index_type|
            default_filename = index_prefix + @indexer_for.to_s.gsub('::', '_')
            hash.fetch(index_type) { "#{default_filename}_#{index_type}" }
          end
        end


        # Called when the neo4j shutdown in order to release references to indexes
        def on_neo4j_shutdown
           @indexes.clear
         end

        # Called from the event handler when a new node or relationships is about to be committed.
        def update_index_on(node, field, old_val, new_val)
          if index?(field)
            rm_index(node, field, old_val) if old_val
            add_index(node, field, new_val) if new_val
          end
        end

        # Called from the event handler when deleting a property
        def remove_index_on(node, old_props)
          @config.fields.each { |field| rm_index(node, field, old_props[field]) if old_props[field] }
        end

        protected

        def index_prefix
          return "" unless Neo4j.running?
          return "" unless @indexer_for.respond_to?(:ref_node_for_class)
          ref_node = @indexer_for.ref_node_for_class.wrapper
          prefix = ref_node.send(:_index_prefix) if ref_node.respond_to?(:_index_prefix)
          prefix ||= ref_node[:name] # To maintain backward compatiblity
          prefix.blank? ? "" : prefix + "_"
        end


        def inherit_fields_from(parent_index)
          # TODO
          raise "not implemented" if true
          return unless parent_index
          @field_types.reverse_merge!(parent_index.field_types) if parent_index.respond_to?(:field_types)
          @parent_indexers << parent_index
        end

        def indexed_value_for(field, value)
          if @config.numeric?(field)
            org.neo4j.index.lucene.ValueContext.new(value).indexNumeric
          else
            org.neo4j.index.lucene.ValueContext.new(value)
          end
        end

         def index_for_field(field) #:nodoc:
           type = @config.index_type(field)
           @indexes[index_key(type)] ||= create_index_with(type)
         end

         def index_for_type(type)
           @indexes[index_key(type)] ||= create_index_with(type)
         end

         def index_key(type)
           index_names[type] + type.to_s
         end

         def lucene_config(type) #:nodoc:
           conf = Neo4j::Config[:lucene][type.to_s]
           raise "unknown lucene type #{type}" unless conf
           conf
         end

         def create_index_with(type) #:nodoc:
           db = Neo4j.started_db
           index_config = lucene_config(type)
           if config.entity_type == :node
             db.lucene.for_nodes(index_names[type], index_config)
           else
             raise "O no"
             db.lucene.for_relationships(index_names[type], index_config)
           end
         end


      end
    end
  end
end