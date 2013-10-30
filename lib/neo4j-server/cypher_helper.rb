module Neo4j::Server
  module CypherHelper
    # Cypher Helper
    def escape_value(value)
      case value
        when String
          "'#{value}'" # TODO escape ' and "
        else
          value
      end
    end

    # Cypher Helper
    def cypher_prop_list(props)
      return "" unless props
      list = props.keys.map{|k| "#{k} : #{escape_value(props[k])}"}.join(',')
      "{#{list}}"
    end


  end

end
