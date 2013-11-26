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
          _raise_invalid_session_error(session)
        end
      end

      private
        def _raise_invalid_session_error(session)
          raise Session::InvalidSessionTypeError.new(session.class)
        end
    end
  end
end