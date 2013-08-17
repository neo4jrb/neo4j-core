module Neo4j::Core
# wrapps Neo4j ResourceIterator, automatically close it

  module ArgumentHelper

    def self.db(args)
      args.last.respond_to?(:create_node) ? args.pop : Neo4j::Database.instance
    end
  end

  class ResourceIterator
    include Enumerable
    def initialize(iterable)
      @_iterable = iterable
    end

    def each
      iterator = @_iterable.iterator
      while (iterator.has_next)
        yield iterator.next
      end
    ensure
      iterator.close
    end
  end

  module TxMethods
    def tx_methods(*methods)
      methods.each do |method|
        tx_method = "#{method}_in_tx"
        send(:alias_method, tx_method, method)
        send(:define_method, method) do |*args, &block|
          db = args.last.respond_to?(:auto_commit?) ? args.last : Neo4j::Database.instance
          Neo4j::Transaction.run(db.auto_commit?) { send(tx_method, *args, &block) }
        end
      end
    end
  end


end
