module Neo4j::Core

  class QueryBuilder
    include CypherTranslator

    DEFAULT_VAR_NAME = :n

    class InvalidQueryError < StandardError;
    end

    def initialize(map_return={})
      @map_return = map_return
      @map_return[:node] = ->(id) { "ID(#{id})" }
    end

    # TODO should be moved somewhere else
    def self.default_cypher_map_return_procs
      {
          id_to_node: ->(column) { Neo4j::Node.load(column) },
          to_node: ->(column) { column.wrapper }, # for embedded db
          value: ->(column) { column },
          id_to_rel: ->(column) { Neo4j::Relationship.load(column) },
          to_rel: ->(column) { column.wrapper } # for embedded db
      }
    end


    def to_query_hash(params, default_map_return)
      if params.first.is_a?(Hash)
        hash = params.first.clone
        hash[:map_return] ||= default_map_return unless hash[:q] || hash[:return]
        hash[:map_return] ||= :value if hash[:return].is_a?(Symbol)
        return hash
      else
        hash = (params[1] && params[1].clone) || {}
        hash[:q] = params[0]
        return hash
      end
    end

    def to_map_return_procs(query_hash)
      map_return_procs = query_hash[:map_return_procs] || self.class.default_cypher_map_return_procs
      map_return = query_hash[:map_return]
      case map_return
        when NilClass
          return {}
        when Symbol, String
          return map_return_procs[map_return.to_sym]
        when Hash
          map_return.keys.inject({}) do |ack, key|
            proc_key = map_return[key]
            ack[key] = map_return_procs[proc_key]
            raise InvalidQueryError.new("Illegal map_return, '#{ack[key]}' not defined for #{key}") unless ack[key]
            ack
          end
      end
    end

    def to_cypher(query_hash)
      return query_hash[:q] if query_hash[:q]
      match_parts = label_parts(query_hash[:label])
      match_parts += match_parts(query_hash[:match])
      conditions_parts = conditions_parts(query_hash[:conditions])
      conditions_parts += where_parts(query_hash[:where])

      return_parts = return_parts(query_hash)
      return_parts += order_parts(query_hash[:order])
      return_parts += skip_parts(query_hash[:skip])
      return_parts += limit_parts(query_hash[:limit])

      cypher = "MATCH #{match_parts.join(',')}"
      cypher += " WHERE #{conditions_parts.join(' AND ')}" if !conditions_parts.empty?
      cypher + " RETURN #{return_parts.join(' ')}"
    end


    def order_parts(order)
      return [] unless order
      cypher = "ORDER BY "

      handleHash = Proc.new do |hash|
        if (hash.is_a?(Hash))
          k, v = hash.first
          raise "only :asc or :desc allowed in order, got #{query.inspect}" unless [:asc, :desc].include?(v)
          v.to_sym == :asc ? "#{DEFAULT_VAR_NAME}.`#{k}`" : "#{DEFAULT_VAR_NAME}.`#{k}` DESC"
        else
          "#{DEFAULT_VAR_NAME}.`#{hash}`" unless hash.is_a?(Hash)
        end
      end

      case order
        when Array
          cypher += order.map(&handleHash).join(', ')
        when Hash
          cypher += handleHash.call(order)
        else
          cypher += "#{DEFAULT_VAR_NAME}.`#{order}`"
      end

      [cypher]
    end

    def return_parts(query_hash)
      query_hash[:return] ? [cypher_return(query_hash[:return])] : [cypher_default_return(query_hash[:label], query_hash)]
    end

    def cypher_return(ret)
      case ret
        when Array
          ret.map { |r| cypher_return_val(r) }.join(',')
        when String, Symbol
          cypher_return_val(ret)
      end

    end

    def cypher_default_return(label, query_hash)
      raise InvalidQueryError, "Can't have default return for two labels" if label.is_a?(Hash) && label.key.size > 1
      if (query_hash[:map_return] == :id_to_node)
        label.is_a?(Hash) ? "ID(#{label.key.first})" : "ID(#{DEFAULT_VAR_NAME})"
      elsif (query_hash[:map_return] == :to_node)
        label.is_a?(Hash) ? "#{label.key.first}" : "#{DEFAULT_VAR_NAME}"
      else
          raise InvalidQueryError.new("Don't know how to generate a cypher return #{query_hash.inspect}")
      end

    end


    def where_parts(conditions)
      return [] unless conditions
      conditions.is_a?(Array) ? conditions : [conditions]
    end

    def limit_parts(limit)
      return [] unless limit
      raise InvalidQueryError.new ":limit value not a number" unless limit.is_a?(Integer)
      return ["LIMIT #{limit}"]
    end

    def skip_parts(skip)
      return [] unless skip
      raise InvalidQueryError.new ":skip value not a number" unless skip.is_a?(Integer)
      return ["SKIP #{skip}"]
    end

    def conditions_parts(conditions)

      return [] unless conditions
      neo_id = conditions.delete(:neo_id)
      conditions["id(#{as})"] = neo_id if neo_id

      conditions.map do |key, value|
        value = '' if value.nil?
        operator, value_string = case value
                                   when Regexp
                                     pattern = (value.casefold? ? "(?i)" : "") + value.source
                                     ['=~', escape_value(pattern.gsub(/\\/, '\\\\\\'))]
                                   else
                                     ['=', escape_value(value)]
                                 end

        k = key.to_s.dup
        k = "#{DEFAULT_VAR_NAME}.#{k}" unless k.match(/[\(\.]/)
        k + operator + value_string.to_s
      end
    end

    def label_parts(label)
      case label
        when NilClass then
          []
        when Hash
          label.map { |variable, label_name| "(#{variable}:`#{label_name}`)" }
        else
          ["(n:`#{label}`)"]
      end
    end


    def match_parts(match)
      case match
        when Array then
          return match
        when String then
          return [match]
        when NilClass
          return []
        else
          raise InvalidQueryError, "Invalid value for 'match' query key #{match.inspect}"
      end
    end

    def cypher_return_val(val)
      val.is_a?(Symbol) ? "#{DEFAULT_VAR_NAME}.`#{val}` AS `#{val}`" : val
    end

  end

end

