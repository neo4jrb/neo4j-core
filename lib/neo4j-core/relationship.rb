module Neo4j
  module Relationship
    class << self
      # Creates a new Relationship and immediately persists it to the database. All subsequent changes are immediately persisted.
      #
      # @param start_node [Node] The node from which the relationship starts i.e. is outgoing.
      # @param end_node [Node] The node at which the relationship ends i.e. is incoming.
      # @param attributes [Hash] An optional hash of properties to initialize the relationship with.
      #
      # @return [Relationship] A new relationship.
      #
      def new(start_node, name, end_node, attributes = {})
        start_node.create_rel_to(end_node, name, attributes)
      end

      # Loads an existing relationship with the given id
      #
      # @param id [Integer] The id of the relationship to be loaded and returned.
      # @param session [Session] An optional session from where to load the node.
      #
      # @return [Relationship] An existing relationship with the given id and specified session.
      #   It returns nil if the node is not found.
      #
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