module Neo4j::Core
  module CypherTranslator
    # Cypher Helper
     def escape_value(value)
       result = case value
         when String
           sanitized = sanitize_escape_sequences(value)
           "'#{escape_quotes(sanitized)}'"
         else
           value
       end
       result
     end

     # Only following escape sequence characters are allowed in Cypher:
     #
     # \t Tab
     # \b Backspace
     # \n Newline
     # \r Carriage return
     # \f Form feed
     # \' Single quote
     # \" Double quote
     # \\ Backslash
     #
     # From:
     # http://docs.neo4j.org/chunked/stable/cypher-expressions.html#_note_on_string_literals
     SANITIZE_ESCAPED_REGEXP = /(?<!\\)\\(\\\\)*(?![futbnr'"\\])/
     def sanitize_escape_sequences(s)
       s.gsub SANITIZE_ESCAPED_REGEXP, ''
     end

     def escape_quotes(s)
       s.gsub("'", %q(\\\'))
     end

    # Cypher Helper
    def cypher_prop_list(props)
      return "" unless props

      properties_to_set = props.reject {|k,v| v.nil? }

      list = properties_to_set.map{|k,v| "#{k} : #{escape_value(v)}"}.join(',')
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
