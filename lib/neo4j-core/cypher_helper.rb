module Neo4j::Core
  module CypherTranslator
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

    # Stolen from keymaker
    # https://github.com/therubymug/keymaker/blob/master/lib/keymaker/parsers/cypher_response_parser.rb
    def self.translate_response(response_body, result)
      Hashie::Mash.new(Hash[sanitized_column_names(response_body).zip(result)])
    end

    def self.sanitized_column_names(response_body)
      response_body.columns.map do |column|
        column[/[^\.]+$/]
      end
    end

  end

end
