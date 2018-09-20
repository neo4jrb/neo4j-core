# frozen_string_literal: true

module Neo4j
  module Core
    module BoltRouting
      class Connection
        attr_reader :client

        def initialize(host_port, client, release)
          @host_port = host_port
          @client = client
          @release = release
        end

        def release
          @release.call(@host_port, self)
        end
      end
    end
  end
end
