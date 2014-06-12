module Neo4j::Core
  module QueryConditions

    class Condition
      attr_reader :value

      def initialize(value)
        @value = value
      end

      class << self
        def from_args(args)
          args.map do |arg|
            if arg.is_a?(String)
              self.from_string arg

            elsif arg.is_a?(Symbol) && self.respond_to?(:from_symbol)
              self.from_symbol arg

            elsif arg.is_a?(Integer) && self.respond_to?(:from_integer)
              self.from_integer arg

            elsif arg.is_a?(Hash)
              if self.respond_to?(:from_hash)
                self.from_hash arg
              elsif self.respond_to?(:from_key_and_value)
                arg.map do |key, value|
                  self.from_key_and_value key, value
                end
              else
                raise ArgumentError, "Invalid argument"
              end

            elsif arg.is_a?(Array) && self.respond_to?(:from_string)
              arg.map do |value|
                self.from_args value
              end

            else
              raise ArgumentError, "Invalid argument"
            end
          end.flatten.map {|value| self.new(value) }
        end

        def from_string(value)
          value
        end

        def node_from_key_and_value(key, value, options = {})
          prefer = options[:prefer] || :var

          var, label_string, attributes_string = nil

          case value
          when String
            var = key
            label_string = value
          when Hash
            if !value.values.any? {|v| v.is_a?(Hash) }
              case prefer
              when :var
                var = key
              when :label
                label_string = key
              end
            else
              var = key
            end

            if value.size == 1 && value.values.first.is_a?(Hash)
              label_string, attributes = value.first
              attributes_string = attributes_string(attributes)
            else
              attributes_string = attributes_string(value)
            end
          when Class
            var = key
            label_string = defined?(value::CYPHER_LABEL) ? value::CYPHER_LABEL : value.name
          else
            raise ArgumentError, "Invalid value type: #{value.inspect}"
          end

          "(#{var}#{format_label(label_string)}#{attributes_string})"
        end

        def to_cypher(conditions)
          "#{@keyword} #{condition_string(conditions)}"
        end

        private

        def format_label(label_string)
          label_string = label_string.to_s.strip
          label_string = ":#{label_string}" if !label_string.empty? && label_string[0] != ':'
          label_string
        end

        def attributes_string(attributes)
          attributes_string = attributes.map do |key, value|
            "#{key}: #{value.inspect}"
          end.join(', ')

          " {#{attributes_string}}"
        end
      end
    end

    class StartCondition < Condition
      @keyword = 'START'

      class << self
        def from_symbol(value)
          from_string(value.to_s)
        end

        def from_key_and_value(key, value)
          case value
          when String, Symbol
            "#{key} = #{value}"
          else
            raise "Need better error"
          end
        end

        def condition_string(conditions)
          conditions.map(&:value).join(', ')
        end
      end
    end

    class WhereCondition < Condition
      @keyword = 'WHERE'

      class << self
        def from_key_and_value(key, value)
          if value.is_a?(Hash)
            value.map do |k, v|
              key.to_s + '.' + from_key_and_value(k, v)
            end.join(' AND ')
          else
            "#{key} = #{value.inspect}"
          end
        end

        def condition_string(conditions)
          conditions.map(&:value).join(' AND ')
        end
      end
    end


    class MatchCondition < Condition
      @keyword = 'MATCH'

      def value
        "#{@value}"
      end

      class << self
        def from_symbol(value)
          from_string(value.to_s)
        end

        def from_key_and_value(key, value)
          self.node_from_key_and_value(key, value)
        end

        def condition_string(conditions)
          conditions.map(&:value).join(', ')
        end
      end
    end

    class CreateCondition < Condition
      @keyword = 'CREATE'

      def value
        "#{@value}"
      end

      class << self
        def from_string(value)
          "(#{value})"
        end

        def from_symbol(value)
          from_string(value.to_s)
        end

        def from_hash(hash)
          if hash.values.any? {|value| value.is_a?(Hash) }
            hash.map do |key, value|
              from_key_and_value(key, value)
            end
          else
            "(#{attributes_string(hash)})"
          end
        end

        def from_key_and_value(key, value)
          self.node_from_key_and_value(key, value, prefer: :label)
        end

        def condition_string(conditions)
          conditions.map(&:value).join(', ')
        end
      end
    end

    class OrderCondition < Condition
      @keyword = 'ORDER BY'

      class << self
        def from_symbol(value)
          from_string(value.to_s)
        end

        def from_key_and_value(key, value)
          "#{key} #{value.upcase}"
        end

        def condition_string(conditions)
          conditions.map(&:value).join(', ')
        end
      end
    end

    class LimitCondition < Condition
      @keyword = 'LIMIT'

      class << self
        def from_string(value)
          value.to_i
        end

        def from_integer(value)
          value
        end

        def condition_string(conditions)
          conditions.last.value
        end
      end
    end

    class SkipCondition < Condition
      @keyword = 'SKIP'

      class << self
        def from_string(value)
          value.to_i
        end

        def from_integer(value)
          value
        end

        def condition_string(conditions)
          conditions.last.value
        end
      end
    end

    class ReturnCondition < Condition
      @keyword = 'RETURN'

      class << self
        def from_symbol(value)
          from_string(value.to_s)
        end

        def from_key_and_value(key, value)
          case value
          when Array
            value.map do |v|
              from_key_and_value(key, v)
            end.join(', ')
          when String, Symbol
            "#{key}.#{value}"
          else
            raise "Need better error"
          end
        end

        def condition_string(conditions)
          conditions.map(&:value).join(', ')
        end
      end
    end


  end
end

