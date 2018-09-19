# frozen_string_literal: true

require 'resolv'

module Neo4j
  module Core
    module BoltRouting
      class DNSHostNameResolver
        def resolve(seed_router)
          host, port = seed_router.split(':')

          Concurrent::Promises.future(host, port, seed_router) do |host, port, seed_router|
            begin
              resolver = Resolv::DNS.new
              addresses = resolver.getaddresses(host)

              addresses.map do |address|
                if address.is_a?(Resolv::IPv6)
                  "[#{ address.to_s }]:#{ port }"
                elsif address.is_a?(Resolv::IPv4)
                  "#{ address.to_s }:#{ port }"
                else
                  raise "Unknown address type: #{ address }."
                end
              end
            rescue
              [seed_router]
            end
          end
        end
      end
    end
  end
end
