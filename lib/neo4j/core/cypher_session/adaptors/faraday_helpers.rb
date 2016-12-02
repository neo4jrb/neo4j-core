module Neo4j
  module Core
    class CypherSession
      module Adaptors
        module FaradayHelpers
          private

          def extract_adapter(faraday_options = {})
            (faraday_options[:adapter] || faraday_options['adapter'] || :net_http_persistent).to_sym.tap do |adapter|
              require 'typhoeus/adapters/faraday' if adapter == :typhoeus
            end
          end
        end
      end
    end
  end
end
