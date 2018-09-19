# frozen_string_literal: true

module Neo4j
  module Core
    module BoltRouting
      class DNSHostNameResolver
        def resolve(seed_router)
          parsed_uri = URI(seed_router)
          Resolv.getaddresses(parsed_uri.host)
        rescue
          [seed_router]
        end
      end
    end
  end
end
