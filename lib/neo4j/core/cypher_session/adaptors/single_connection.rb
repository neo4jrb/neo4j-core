# frozen_string_literal: true

require 'neo4j/core/cypher_session/adaptors/bolt'

module Neo4j
  module Core
    class CypherSession
      module Adaptors
        class SingleConnection < Bolt
          def initialize(connection)
            @options = {}
            @tcp_client = connection.client
          end

          def connect; end
        end
      end
    end
  end
end
