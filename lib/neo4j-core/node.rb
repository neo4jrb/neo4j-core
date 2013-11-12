require "helpers/argument_helpers"

module Neo4j
  module Node
    autoload :Rest, "neo4j-core/node/rest"
    extend Neo4j::ArgumentHelpers

    class << self
      def new(attributes, *args)
        session = extract_session(args)
        labels = args.flatten

        begin
          session.class.create_node(attributes, labels, session)
        rescue NoMethodError => e
          raise Neo4j::Session::InvalidSessionType.new(session.class.to_s)
        end
      end

      def load(id, session = Neo4j::Session.current)
        begin
          session.class.load(id, session)
        rescue NoMethodError => e
          raise Neo4j::Session::InvalidSessionType.new(session.class.to_s)
        end
      end
    end
  end
end