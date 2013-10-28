module Neo4j::Core
# wrapps Neo4j ResourceIterator, automatically close it

  module ArgumentHelper

    def self.session(args)
      args.last.kind_of?(Neo4j::Session) ? args.pop : Neo4j::Session.current
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
      iterator && iterator.close
    end
  end

  module TxMethods
    def tx_methods(*methods)
      methods.each do |method|
        tx_method = "#{method}_in_tx"
        send(:alias_method, tx_method, method)
        send(:define_method, method) do |*args, &block|
          session = ArgumentHelper.session(args)
          Neo4j::Transaction.run(session.auto_commit?) { send(tx_method, *args, &block) }
        end
      end
    end
  end

  def self.symbolize!(hash)
    hash.keys.each do |key|
      hash[(key.to_sym rescue key) || key] = hash.delete(key)
    end
  end

end
