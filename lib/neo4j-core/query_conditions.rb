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
            if arg.is_a?(String) && self.respond_to?(:from_string)
              self.from_string arg

            elsif arg.is_a?(Symbol) && self.respond_to?(:from_symbol)
              self.from_symbol arg

            elsif arg.is_a?(Integer) && self.respond_to?(:from_integer)
              self.from_integer arg

            elsif arg.is_a?(Hash) && self.respond_to?(:from_field_and_value)
              arg.map do |key, value|
                self.from_field_and_value key, value
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

        def field(value)
          if [:id, :neo_id].include?(value.to_sym)
            'ID(n)'
          else
            value
          end
        end

        def to_cypher(conditions)
          "#{@keyword} #{condition_string(conditions)}"
        end
      end
    end

    class WhereCondition < Condition
      @keyword = 'WHERE'

      class << self
        def from_string(value)
          value
        end

        def from_field_and_value(field, value)
          if value.is_a?(Hash)
            value.map do |k, v|
              field.to_s + '.' + from_field_and_value(k, v)
            end.join(' AND ')
          else
            "#{self.field(field)} = #{value.inspect}"
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
        def from_string(value)
          value
        end

        def from_symbol(value)
          from_string(value.to_s)
        end

        def from_field_and_value(field, label)
          label_string, attributes_string = 
            case label
            when String
              label
            when Hash
              if label.size == 1 && label.values.first.is_a?(Hash)
                label, attributes = label.first
                [label, attributes_string(attributes)]
              else
                [nil, attributes_string(label)]
              end
            when Class
              defined?(label::CYPHER_LABEL) ? label::CYPHER_LABEL : label.name
            else
              raise ArgumentError, "Invalid label type: #{label.inspect}"
            end

            label_string = ":#{label_string}" if label_string
            attributes_string = " {#{attributes_string}}" if attributes_string

            "#{self.field(field)}#{label_string}#{attributes_string}"
        end

        def condition_string(conditions)
          conditions.map(&:value).join(', ')
        end

        private

        def attributes_string(attributes)
          attributes.map do |key, value|
            "#{key}: #{value.inspect}"
          end.join(', ')
        end
      end
    end

    class OrderCondition < Condition
      @keyword = 'ORDER BY'

      class << self
        def from_string(value)
          self.field(value)
        end

        def from_symbol(value)
          from_string(value.to_s)
        end

        def from_field_and_value(field, label)
          "#{self.field(field)} #{label.upcase}"
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

    class ReturnCondition < Condition
      @keyword = 'RETURN'

      class << self
        def from_string(value)
          value
        end

        def condition_string(conditions)
          conditions.map(&:value).join(', ')
        end
      end
    end


  end
end

