module Neo4j
  module Core
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
  end
end
