module Neo4j
  module Core
    class CypherSession
      module Adaptors
        module FaradayHelpers
          private

          def verify_faraday_options(faraday_options = {}, defaults = {})
            faraday_options.symbolize_keys!.reverse_merge!(defaults)
            faraday_options[:adapter] ||= :net_http_persistent
            require 'typhoeus/adapters/faraday' if faraday_options[:adapter].to_sym == :typhoeus
            faraday_options
          end

          def set_faraday_middleware(faraday, options = {adapter: :net_http_persistent})
            adapter = options.delete(:adapter)
            send_all_faraday_options(faraday, options)
            faraday.adapter adapter
          end

          def send_all_faraday_options(faraday, options)
            options.each do |key, value|
              next unless faraday.respond_to? key
              if value.is_a? Array
                if value.none? { |arg| arg.is_a? Array }
                  faraday.send key, *value
                else
                  value.each do |args|
                    arg_safe_send faraday, key, args
                  end
                end
              else
                faraday.send key, value
              end
            end
          end

          def arg_safe_send(object, msg, args)
            if args.is_a? Array
              object.send(msg, *args)
            else
              object.send(msg, args)
            end
          end
        end
      end
    end
  end
end
