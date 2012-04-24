module Neo4j
  module Core

    module Index

      # A Utility class that can be used to make it easier to create unique entities. It uses {Neo4j::Core::Index::Indexer#put_if_absent}.
      #
      # @see Indexer#put_if_absent
      #
      # @example
      #   index = index_for_type(:exact)
      #   Neo4j::Core::Index::UniqueFactory.new(:email, index) { |k,v| Neo4j::Node.new(k => v) }.get_or_create(:email, 'foo@gmail.com')
      #
      class UniqueFactory
        # @param [Symbol] key only one key is possible
        # @param [Java::Neo4j] index the lucene index (see #index_for_type)
        # @yield a proc for initialize each created entity
        def initialize(key, index, &entity_creator_block)
          @key = key
          @index = index
          @entity_creator_block = entity_creator_block || Proc.new{|k,v| Neo4j::Node.new(key.to_s => v)}
        end

        # Get the indexed entity, creating it (exactly once) if no indexed entity exists.
        # There must be an index on the key
        # @param [Symbol] key the key to find the entity under in the index.
        # @param [String, Fixnum, Float] value  the value the key is mapped to for the entity in the index.
        # @param [Hash] props optional properties that the entity will have if created
        # @yield optional, make it possible to initialize the created node in a block
        def get_or_create(key, value, props=nil, &init_block)
          tx = Neo4j::Transaction.new
          result = @index.get(key.to_s, value).get_single
          return result if result

          created = @entity_creator_block.call(key,value)
          result = @index.put_if_absent(created._java_entity, key.to_s, value)
          if result.nil?
            props.each_pair{|k,v| created[k.to_s] = v} if props
            init_block.call(result) if init_block
            result = created
          else
            created.del
          end
          tx.success
          result
        ensure
          tx.finish
        end

      end
    end

  end
end