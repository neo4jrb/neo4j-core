require "helpers/argument_helpers"

module Neo4j
  module Node
    autoload :Rest, "neo4j-core/node/rest"
    extend Neo4j::ArgumentHelpers

    class << self
      def new(attributes, *args)
        session = extract_session(args)
        labels = args

        if session.is_a? Neo4j::Session::Rest
          Rest.new(attributes, labels, session)
        elsif session.is_a? Neo4j::Session::Embedded 
          session.create_node(attributes, labels)
        else
          raise Neo4j::Session::InvalidSessionType.new(session.class.to_s)
        end
      end
    end
  end
end