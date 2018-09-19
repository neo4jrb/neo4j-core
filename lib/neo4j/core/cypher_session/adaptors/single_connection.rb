# frozen_string_literal: true

require 'neo4j/core/cypher_session/adaptors/bolt'

module Neo4j
  module Core
    class CypherSession
      module Adaptors
        class SingleConnection < Bolt
          def initialize(tcp_client)
            @options = {}
            @tcp_client = tcp_client
          end

          def connect; end
        end
      end
    end
  end
end
