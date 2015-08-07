module Neo4j
  module Core
    module TxMethods
      def tx_methods(*methods)
        methods.each do |method|
          tx_method = "#{method}_in_tx"
          send(:alias_method, tx_method, method)
          send(:define_method, method) do |*labels_or_db, &block|
            session = args.last.is_a?(Neo4j::Session) ? args.pop : Neo4j::Session.current!

            Neo4j::Transaction.run(session.auto_commit?) { send(tx_method, *args, &block) }
          end
        end
      end
    end
  end
end
