module Neo4j::Core
  class CypherQuery
    class QueryElement
      attr_reader :var_name
      attr_accessor :id, :labels, :rel_type, :conditions, :returns, :order, :dir

      def initialize(var_name, rel=false)
        @var_name = var_name
        @rel = rel

        @dir = rel ? :both : nil
        self
      end

      def labels=(labels)
        @labels = labels.is_a?(Array) ? labels : [labels]
      end

      def label=(label)
        @labels ||= []

        case label
        when Array
          @labels += label
        when String, Symbol
          @labels << label
        end

        @labels
      end

      def remove_label(label)
        labels.each_index.select{|i| labels.delete_at(i) if labels[i] == label}
      end

      def selectors
        if rel?
          return rel_type ? [rel_type] : nil
        end

        labels
      end

      def neo_type
        rel? ? :relationship : :node
      end

      def rel?
        @rel
      end

      def print_clause(clause)
        send("#{clause}_template")
      end

      private

      def start_template
        "#{var_name}=#{neo_type}(#{id})" if id
      end

      def match_template
        dir_func = {incoming: ->(str) {"<-#{str}-"},
                    outgoing: ->(str) {"-#{str}->"},
                    both:     ->(str) {"-#{str}-"}}

        encase = {relationship: ->(str) {"#{dir_func[dir].call("[#{str}]")}"},
                  node:         ->(str) {"(#{str})"}}

        selector_str = selectors ? selectors.map{|sel| ":`#{sel}`"}.join : nil

        encase[neo_type].call("#{var_name}#{selector_str}")
      end

      def where_template
        return nil unless conditions

        conditions.keys.map do |k|
          value = conditions[k]
          prefix = "#{var_name}.#{k}="

          if value.is_a? Regexp
            pattern = (value.casefold? ? "(?i)" : "") + value.source
            prefix + "~#{escape_value(pattern.gsub(/\\/, '\\\\\\'))}"           
          else 
            prefix + "#{escape_value(conditions[k])}"
          end
        end
      end

      def order_template
        return nil unless order

        handleHash = Proc.new do |hash|
          if (hash.is_a?(Hash))
            k, v = hash.first
            raise "only :asc or :desc allowed in order, got #{query.inspect}" unless [:asc, :desc].include?(v)
            v.to_sym == :asc ? "#{var_name}.`#{k}`" : "#{var}.`#{k}` DESC"
          else
            "#{var}.`#{hash}`" unless hash.is_a?(Hash)
          end
        end

        case order
        when Array
          cypher += order.map(&handleHash).join(', ')
        when Hash
          cypher += handleHash.call(order)
        else
          cypher += "#{var}.`#{order}`"
        end
      end

      def return_template
        return nil unless returns

        case returns
        when Array
          returns.map{|fn| "#{fn}(#{var_name})"}.join(',')
        when Symbol
          "#{returns}(#{var_name})"
        when Boolean
          var_name
        else
          returns
        end
      end
    end
  end
end
