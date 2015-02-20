module Neo4j
  module Core
    module QueryClauses
      class ArgError < StandardError
        attr_reader :arg_part
        def initialize(arg_part = nil)
          super
          @arg_part = arg_part
        end
      end


      class Clause
        include CypherTranslator

        attr_reader :params

        def initialize(arg, options = {})
          @arg = arg
          @options = options
          @params = {}
        end

        def value
          [String, Symbol, Integer, Hash].each do |arg_class|
            from_method = "from_#{arg_class.name.downcase}"
            return send(from_method, @arg) if @arg.is_a?(arg_class) && self.respond_to?(from_method)
          end

          fail ArgError
        rescue ArgError => arg_error
          message = "Invalid argument for #{self.class.keyword}.  Full arguments: #{@arg.inspect}"
          message += " | Invalid part: #{arg_error.arg_part.inspect}" if arg_error.arg_part

          raise ArgumentError, message
        end

        def from_hash(value)
          if self.respond_to?(:from_key_and_value)
            value.map do |k, v|
              from_key_and_value k, v
            end
          else
            fail ArgError
          end
        end

        def from_string(value)
          value
        end

        def node_from_key_and_value(key, value, options = {})
          var = var_from_key_and_value(key, value, options[:prefer] || :var)
          label = label_from_key_and_value(key, value, options[:prefer] || :var)
          attributes = attributes_from_key_and_value(key, value)

          "(#{var}#{format_label(label)}#{attributes_string(attributes)})"
        end

        def var_from_key_and_value(key, value, prefer = :var)
          case value
          when String, Symbol, Class, Module, NilClass
            key
          when Hash
            key if value.values.any? { |v| v.is_a?(Hash) } || prefer == :var
          else
            fail ArgError, value
          end
        end

        def label_from_key_and_value(key, value, prefer = :var)
          case value
          when String, Symbol
            value
          when Class, Module
            defined?(value::CYPHER_LABEL) ? value::CYPHER_LABEL : value.name
          when Hash
            if value.values.map(&:class) == [Hash]
              value.first.first
            else
              key if value.values.none? { |v| v.is_a?(Hash) } && prefer == :label
            end
          when NilClass
            nil
          else
            fail ArgError, value
          end
        end

        def attributes_from_key_and_value(key, value)
          return nil unless value.is_a?(Hash)

          if value.values.map(&:class) == [Hash]
            value.first[1]
          else
            value
          end
        end

        class << self
          attr_reader :keyword

          def from_args(args, options = {})
            args.flatten.map do |arg|
              new(arg, options) if !arg.respond_to?(:empty?) || !arg.empty?
            end.compact
          end

          def to_cypher(clauses)
            string = clause_string(clauses)
            string.strip!

            "#{@keyword} #{string}" if string.size > 0
          end
        end

        private

        def key_value_string(key, value, previous_keys = [], force_equals = false)
          param = (previous_keys << key).join('_')
          param.gsub!(/[^a-z0-9]+/i, '_')
          param.gsub!(/^_+|_+$/, '')
          @params[param.to_sym] = value

          if !value.is_a?(Array) || force_equals
            "#{key} = {#{param}}"
          else
            "#{key} IN {#{param}}"
          end
        end

        def format_label(label_string)
          label_string = label_string.to_s
          label_string.strip!
          if !label_string.empty? && label_string[0] != ':'
            label_string = "`#{label_string}`" unless label_string.match(' ')
            label_string = ":#{label_string}"
          end
          label_string
        end

        def attributes_string(attributes)
          return '' if not attributes

          attributes_string = attributes.map do |key, value|
            v = if value.nil?
                  'null'
                else
                  value.to_s.match(/^{.+}$/) ? value : value.inspect
                end
            "#{key}: #{v}"
          end.join(', ')

          " {#{attributes_string}}"
        end
      end

      class StartClause < Clause
        @keyword = 'START'

        def from_symbol(value)
          from_string(value.to_s)
        end

        def from_key_and_value(key, value)
          case value
          when String, Symbol
            "#{key} = #{value}"
          else
            fail ArgError, value
          end
        end

        class << self
          def clause_string(clauses)
            clauses.map!(&:value).join(', ')
          end
        end
      end

      class WhereClause < Clause
        @keyword = 'WHERE'

        def from_key_and_value(key, value, previous_keys = [])
          case value
          when Hash then hash_key_value_string(key, value, previous_keys)
          when NilClass then "#{key} IS NULL"
          when Regexp then regexp_key_value_string(key, value)
          when Array then key_value_string(key, value, previous_keys)
          else
            key_value_string(key, value, previous_keys)
          end
        end

        class << self
          def clause_string(clauses)
            clauses.map(&:value).flatten.map { |value| "(#{value})" }.join(' AND ')
          end
        end

        private

        def hash_key_value_string(key, value, previous_keys)
          value.map do |k, v|
            if k.to_sym == :neo_id
              key_value_string("ID(#{key})", v.to_i)
            else
              "#{key}.#{from_key_and_value(k, v, previous_keys + [key])}"
            end
          end.join(' AND ')
        end

        def regexp_key_value_string(key, value)
          pattern = (value.casefold? ? '(?i)' : '') + value.source
          "#{key} =~ #{escape_value(pattern.gsub(/\\/, '\\\\\\'))}"
        end
      end


      class MatchClause < Clause
        @keyword = 'MATCH'

        def from_symbol(value)
          from_string(value.to_s)
        end

        def from_key_and_value(key, value)
          node_from_key_and_value(key, value)
        end

        class << self
          def clause_string(clauses)
            clauses.map!(&:value).join(', ')
          end
        end
      end

      class OptionalMatchClause < MatchClause
        @keyword = 'OPTIONAL MATCH'
      end

      class WithClause < Clause
        @keyword = 'WITH'

        def from_symbol(value)
          from_string(value.to_s)
        end

        def from_key_and_value(key, value)
          "#{value} AS #{key}"
        end

        class << self
          def clause_string(clauses)
            clauses.map!(&:value).join(', ')
          end
        end
      end

      class UsingClause < Clause
        @keyword = 'USING'

        class << self
          def clause_string(clauses)
            clauses.map!(&:value).join(" #{@keyword} ")
          end
        end
      end

      class CreateClause < Clause
        @keyword = 'CREATE'

        def from_string(value)
          value
        end

        def from_symbol(value)
          "(:#{value})"
        end

        def from_hash(hash)
          if hash.values.any? { |value| value.is_a?(Hash) }
            hash.map do |key, value|
              from_key_and_value(key, value)
            end
          else
            "(#{attributes_string(hash)})"
          end
        end

        def from_key_and_value(key, value)
          node_from_key_and_value(key, value, prefer: :label)
        end

        class << self
          def clause_string(clauses)
            clauses.map!(&:value).join(', ')
          end
        end
      end

      class CreateUniqueClause < CreateClause
        @keyword = 'CREATE UNIQUE'
      end

      class MergeClause < CreateClause
        @keyword = 'MERGE'
      end

      class DeleteClause < Clause
        @keyword = 'DELETE'

        def from_symbol(value)
          from_string(value.to_s)
        end

        class << self
          def clause_string(clauses)
            clauses.map!(&:value).join(', ')
          end
        end
      end

      class OrderClause < Clause
        @keyword = 'ORDER BY'

        def from_symbol(value)
          from_string(value.to_s)
        end

        def from_key_and_value(key, value)
          case value
          when String, Symbol
            "#{key}.#{value}"
          when Array
            value.map do |v|
              v.is_a?(Hash) ?  from_key_and_value(key, v) : "#{key}.#{v}"
            end
          when Hash
            value.map { |k, v| "#{key}.#{k} #{v.upcase}" }
          end
        end

        class << self
          def clause_string(clauses)
            clauses.map!(&:value).join(', ')
          end
        end
      end

      class LimitClause < Clause
        @keyword = 'LIMIT'

        def from_string(value)
          clause_id = "#{self.class.keyword.downcase}_#{value}"
          @params[clause_id] = value.to_i
          "{#{clause_id}}"
        end

        def from_integer(value)
          clause_id = "#{self.class.keyword.downcase}_#{value}"
          @params[clause_id] = value
          "{#{clause_id}}"
        end

        class << self
          def clause_string(clauses)
            clauses.last.value
          end
        end
      end

      class SkipClause < Clause
        @keyword = 'SKIP'

        def from_string(value)
          clause_id = "#{self.class.keyword.downcase}_#{value}"
          @params[clause_id] = value.to_i
          "{#{clause_id}}"
        end

        def from_integer(value)
          clause_id = "#{self.class.keyword.downcase}_#{value}"
          @params[clause_id] = value
          "{#{clause_id}}"
        end

        class << self
          def clause_string(clauses)
            clauses.last.value
          end
        end
      end

      class SetClause < Clause
        @keyword = 'SET'

        def from_key_and_value(key, value)
          case value
          when String, Symbol then "#{key} = #{value}"
          when Hash
            if @options[:set_props]
              attribute_string = value.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')
              "#{key} = {#{attribute_string}}"
            else
              value.map { |k, v| key_value_string("#{key}.`#{k}`", v, ['setter'], true) }
            end
          else
            fail ArgError, value
          end
        end

        class << self
          def clause_string(clauses)
            clauses.map!(&:value).join(', ')
          end
        end
      end

      class OnCreateSetClause < SetClause
        @keyword = 'ON CREATE SET'

        def initialize(*args)
          super
          @options[:set_props] = false
        end
      end

      class OnMatchSetClause < OnCreateSetClause
        @keyword = 'ON MATCH SET'
      end

      class RemoveClause < Clause
        @keyword = 'REMOVE'

        def from_key_and_value(key, value)
          case value
          when /^:/
            "#{key}:#{value[1..-1]}"
          when String
            "#{key}.#{value}"
          when Symbol
            "#{key}:#{value}"
          else
            fail ArgError, value
          end
        end

        class << self
          def clause_string(clauses)
            clauses.map!(&:value).join(', ')
          end
        end
      end

      class UnwindClause < Clause
        @keyword = 'UNWIND'

        def from_key_and_value(key, value)
          case value
          when String, Symbol
            "#{value} AS #{key}"
          when Array
            "#{value.inspect} AS #{key}"
          else
            fail ArgError, value
          end
        end

        class << self
          def clause_string(clauses)
            clauses.map!(&:value).join(' UNWIND ')
          end
        end
      end

      class ReturnClause < Clause
        @keyword = 'RETURN'

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
            fail ArgError, value
          end
        end

        class << self
          def clause_string(clauses)
            clauses.map!(&:value).join(', ')
          end
        end
      end
    end
  end
end
