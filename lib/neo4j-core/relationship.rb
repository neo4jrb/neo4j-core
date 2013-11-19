require "neo4j-core/relationship/rest"

module Neo4j
  module Relationship
    class << self
      def new(start_node, name, end_node, attributes = {})
        start_node.create_rel_to(end_node, name, attributes)
      end

      def load(id, session = Session.current)
        begin
          session.load_rel(id)
        rescue NoMethodError
          raise_invalid_session_error(session)
        end
      end

      private
        def raise_invalid_session_error(session)
          raise Neo4j::Session::InvalidSessionTypeError.new(session.class)
        end
    end
  end
end