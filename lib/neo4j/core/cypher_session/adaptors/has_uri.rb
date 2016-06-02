require 'active_support/concern'

module Neo4j
  module Core
    class CypherSession
      module Adaptors
        module HasUri
          extend ActiveSupport::Concern

          module ClassMethods
            attr_reader :default_uri

            def default_url(default_url)
              @default_uri = uri_from_url!(default_url)
            end

            def validate_uri(&block)
              @uri_validator = block
            end

            def uri_from_url!(url)
              fail ArgumentError, "Invalid URL: #{url.inspect}" if !url.is_a?(String)

              @uri = URI(url || @default_url)

              fail ArgumentError, "Invalid URL: #{url.inspect}" if @uri_validator && !@uri_validator.call(@uri)

              @uri
            end
          end

          def url=(url)
            @uri = self.class.uri_from_url!(url)
          end

          included do
            %w(scheme user password host post).each do |method|
              define_method(method) do
                @uri.send(method) || self.class.default_uri.send(method)
              end
            end
          end
        end
      end
    end
  end
end
