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

        attr_accessor :params

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

          prefix_value = value
          if value.is_a?(Hash)
            prefix_value = if value.values.any? { |v| v.is_a?(Hash) }
                             value.keys.join('_')
                           end
          end

          "(#{var}#{format_label(label)}#{attributes_string(attributes, [key, prefix_value].compact.join('_') + '_')})"
        end

        def var_from_key_and_value(key, value, prefer = :var)
          case value
          when String, Symbol, Class, Module, NilClass, Array then key
          when Hash
            key if _use_key_for_var?(value, prefer)
          else
            fail ArgError, value
          end
        end

        def label_from_key_and_value(key, value, prefer = :var)
          case value
          when String, Symbol, Array, NilClass then value
          when Class, Module then value.name
          when Hash
            if value.values.map(&:class) == [Hash]
              value.first.first
            else
              key if !_use_key_for_var?(value, prefer)
            end
          else
            fail ArgError, value
          end
        end

        def _use_key_for_var?(value, prefer)
          _nested_value_hash?(value) || prefer == :var
        end

        def _nested_value_hash?(value)
          value.values.any? { |v| v.is_a?(Hash) }
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
              from_arg(arg, options)
            end.compact
          end

          def from_arg(arg, options = {})
            new(arg, options) if !arg.respond_to?(:empty?) || !arg.empty?
          end

          def to_cypher(clauses)
            @question_mark_param_index = 1

            string = clause_string(clauses)
            string.strip!

            "#{@keyword} #{string}" if string.size > 0
          end
        end

        private

        def key_value_string(key, value, previous_keys = [], force_equals = false)
          param = (previous_keys << key).join('_')
          param.tr_s!('^a-zA-Z0-9', '_')
          param.gsub!(/^_+|_+$/, '')

          value = value.first if value.is_a?(Array) && value.size == 1
          @params[param.to_sym] = value

          if !value.is_a?(Array) || force_equals
            "#{key} = {#{param}}"
          else
            "#{key} IN {#{param}}"
          end
        end

        def format_label(label_arg)
          if label_arg.is_a?(Array)
            return label_arg.map { |arg| format_label(arg) }.join
          end

          label_arg = label_arg.to_s
          label_arg.strip!
          if !label_arg.empty? && label_arg[0] != ':'
            label_arg = "`#{label_arg}`" unless label_arg.match(' ')
            label_arg = ":#{label_arg}"
          end
          label_arg
        end

        def attributes_string(attributes, prefix = '')
          return '' if not attributes

          attributes_string = attributes.map do |key, value|
            if value.to_s.match(/^{.+}$/)
              "#{key}: #{value}"
            else
              param_key = prefix + key.to_s
              @params[param_key.to_sym] = value
              "#{key}: {#{param_key}}"
            end
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
              v = Array(v).map { |item| (item.respond_to?(:neo_id) ? item.neo_id : item).to_i }
              key_value_string("ID(#{key})", v)
            else
              "#{key}.#{from_key_and_value(k, v, previous_keys + [key])}"
            end
          end.join(' AND ')
        end

        def regexp_key_value_string(key, value)
          pattern = (value.casefold? ? '(?i)' : '') + value.source
          "#{key} =~ #{escape_value(pattern.gsub(/\\/, '\\\\\\'))}"
        end

        class << self
          def from_args(args, options = {})
            query_string, params = args
            has_question_mark_regex = /(^|\s)\?(\s|$)/
            if query_string.is_a?(String) && (query_string.match(has_question_mark_regex) || params.is_a?(Hash))
              if !params.is_a?(Hash)
                question_mark_params_param = self.question_mark_params_param
                query_string.gsub!(has_question_mark_regex, "\\1{#{question_mark_params_param}}\\2")
                params = {question_mark_params_param.to_sym => params}
              end

              clause = from_arg(query_string, options).tap do |clause|
                clause.params.merge!(params)
              end

              [clause]
            else
              super
            end
          end

          def question_mark_params_param
            result = "question_mark_param#{@question_mark_param_index}"
            @question_mark_param_index += 1
            result
          end
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
          when String, Symbol then "#{key}:`#{value}`"
          when Hash
            if @options[:set_props]
              attribute_string = value.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')
              "#{key} = {#{attribute_string}}"
            else
              value.map { |k, v| key_value_string("#{key}.`#{k}`", v, ['setter'], true) }
            end
          when Array then value.map { |v| from_key_and_value(key, v) }
          when NilClass then []
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
            "#{key}:`#{value[1..-1]}`"
          when String
            "#{key}.#{value}"
          when Symbol
            "#{key}:`#{value}`"
          when Array
            value.map do |v|
              from_key_and_value(key, v)
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
            if value.to_sym == :neo_id
              "ID(#{key})"
            else
              "#{key}.#{value}"
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
    end
  end
end
