require "helpers/argument_helpers"

module Neo4j
  module Node
    extend Neo4j::ArgumentHelpers

    class << self
      # Creates a new Node and immediately persists it to the database. All subsequent changes are immediately persisted.
      #
      # @param attributes [Hash] The properties to initialize the node with.
      # @param labels [Array] An optional list of labels or an array of labels. Labels can be strings or symbols.
      # @param session [Session] An optional session can be provided as the last value to indicate the database where to create the node.
      #   If none is provided then the current session is assumed.
      #
      # @return [Node] A new node.
      #
      def new(attributes, *args)
        session = extract_session(args)
        labels = args.flatten

        begin
          session.create_node(attributes, labels)
        rescue NoMethodError
          _raise_invalid_session_error(session)
        end
      end

      # Loads an existing node with the given id
      #
      # @param id [Integer] The id of the node to be loaded and returned.
      # @param session [Session] An optional session from where to load the node.
      #
      # @return [Node] An existing node with the given id and specified session. It returns nil if the node is not found.
      #
      def load(id, session = Neo4j::Session.current)
        begin
          session.load(id)
        rescue NoMethodError
          _raise_invalid_session_error(session)
        end
      end

      private
        def _raise_invalid_session_error(session)
          raise Neo4j::Session::InvalidSessionTypeError.new(session.class)
        end
    end
  end
end