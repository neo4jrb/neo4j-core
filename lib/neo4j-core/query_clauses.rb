module Neo4j::Core
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

      def initialize(arg, options = {})
        @arg = arg
        @options = options
      end

      def value
        if @arg.is_a?(String)
          self.from_string @arg

        elsif @arg.is_a?(Symbol) && self.respond_to?(:from_symbol)
          self.from_symbol @arg

        elsif @arg.is_a?(Integer) && self.respond_to?(:from_integer)
          self.from_integer @arg

        elsif @arg.is_a?(Hash)
          if self.respond_to?(:from_hash)
            self.from_hash @arg
          elsif self.respond_to?(:from_key_and_value)
            @arg.map do |key, value|
              self.from_key_and_value key, value
            end
          else
            raise ArgError.new
          end

        else
          raise ArgError.new
        end

      rescue ArgError => arg_error
        message = "Invalid argument for #{self.class.keyword}.  Full arguments: #{@arg.inspect}"
        message += " | Invalid part: #{arg_error.arg_part.inspect}" if arg_error.arg_part

        raise ArgumentError, message
      end

      def from_string(value)
        value
      end

      def node_from_key_and_value(key, value, options = {})
        prefer = options[:prefer] || :var

        var, label_string, attributes_string = nil

        case value
        when String, Symbol
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
        when Class, Module
          var = key
          label_string = defined?(value::CYPHER_LABEL) ? value::CYPHER_LABEL : value.name
        else
          raise ArgError.new(value)
        end

        "(#{var}#{format_label(label_string)}#{attributes_string})"
      end

      class << self
        attr_reader :keyword

        def from_args(args, options = {})
          args.flatten.map do |arg|
            if !arg.respond_to?(:empty?) || !arg.empty?
              self.new(arg, options)
            end
          end.compact
        end

        def to_cypher(clauses)
          "#{@keyword} #{clause_string(clauses)}"
        end
      end

      private

      def format_label(label_string)
        label_string = label_string.to_s.strip
        if !label_string.empty? && label_string[0] != ':'
          label_string = "`#{label_string}`" unless label_string.match(' ')
          label_string = ":#{label_string}"
        end
        label_string
      end

      def attributes_string(attributes)
        attributes_string = attributes.map do |key, value|
          v = value.to_s.match(/^{.+}$/) ? value : value.inspect
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
          raise ArgError.new(value)
        end
      end

      class << self
        def clause_string(clauses)
          clauses.map(&:value).join(', ')
        end
      end
    end

    class WhereClause < Clause
      @keyword = 'WHERE'

      def from_key_and_value(key, value)
        case value
        when Hash
          value.map do |k, v|
            if k.to_sym == :neo_id
              "ID(#{key}) = #{v}"
            else
              key.to_s + '.' + from_key_and_value(k, v)
            end
          end.join(' AND ')
        when Array
          "#{key} IN [#{value.join(', ')}]"
        when NilClass
          "#{key} IS NULL"
        when Regexp
          pattern = (value.casefold? ? "(?i)" : "") + value.source
          "#{key} =~ #{escape_value(pattern.gsub(/\\/, '\\\\\\'))}"
        when /^\{[^\{\}]+\}$/
          "#{key} = #{value}"
        else
          "#{key} = #{value.inspect}"
        end
      end

      class << self
        def clause_string(clauses)
          clauses.map(&:value).join(' AND ')
        end
      end
    end


    class MatchClause < Clause
      @keyword = 'MATCH'

      def from_symbol(value)
        from_string(value.to_s)
      end

      def from_key_and_value(key, value)
        self.node_from_key_and_value(key, value)
      end

      class << self
        def clause_string(clauses)
          clauses.map(&:value).join(', ')
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
          clauses.map(&:value).join(', ')
        end
      end
    end

    class UsingClause < Clause
      @keyword = 'USING'

      class << self
        def clause_string(clauses)
          clauses.map(&:value).join(" #{@keyword} ")
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

      class << self
        def clause_string(clauses)
          clauses.map(&:value).join(', ')
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
          clauses.map(&:value).join(', ')
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
            if v.is_a?(Hash)
              from_key_and_value(key, v)
            else
              "#{key}.#{v}"
            end
          end
        when Hash
          value.map do |k, v|
            "#{key}.#{k} #{v.upcase}"
          end
        end
      end

      class << self
        def clause_string(clauses)
          clauses.map(&:value).join(', ')
        end
      end
    end

    class LimitClause < Clause
      @keyword = 'LIMIT'

      def from_string(value)
        value.to_i
      end

      def from_integer(value)
        value
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
        value.to_i
      end

      def from_integer(value)
        value
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
        when String, Symbol
          "#{key} = #{value}"
        when Hash
          if @options[:set_props]
            value.map do |k, v|
              "#{key}.#{k} = #{v.inspect}"
            end
          else
            attribute_string = value.map {|k, v| "#{k}: #{v.inspect}" }.join(', ')
            "#{key} = {#{attribute_string}}"
          end
        else
          raise ArgError.new(value)
        end
      end

      class << self
        def clause_string(clauses)
          clauses.map(&:value).join(', ')
        end
      end
    end

    class OnCreateSetClause < SetClause
      @keyword = 'ON CREATE SET'

      def initialize(*args)
        super
        @options[:set_props] = true
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
          raise ArgError.new(value)
        end

      end

      class << self
        def clause_string(clauses)
          clauses.map(&:value).join(', ')
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
          raise ArgError.new(value)
        end
      end

      class << self
        def clause_string(clauses)
          clauses.map(&:value).join(' UNWIND ')
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
          raise ArgError.new(value)
        end
      end

      class << self
        def clause_string(clauses)
          clauses.map(&:value).join(', ')
        end
      end
    end


  end
end

