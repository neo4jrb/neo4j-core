module Neo4j::Core
  module CypherTranslator
    # Cypher Helper
    def escape_value(value)
      if value.is_a?(String) || value.is_a?(Symbol)
        "'#{escape_quotes(sanitize_escape_sequences(value.to_s))}'"
      else
        value
      end
    end

    def create_escape_value(value)
      if value.is_a?(String) || value.is_a?(Symbol)
        "#{escape_quotes(sanitize_escape_sequences(value.to_s))}"
      else
        value
      end
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
    EMPTY_PROPS = ''

    def sanitize_escape_sequences(s)
     s.gsub SANITIZE_ESCAPED_REGEXP, EMPTY_PROPS
    end

    def escape_quotes(s)
     s.gsub("'", %q(\\\'))
    end

    # Cypher Helper
    def cypher_prop_list(props)
      return nil unless props
      props.reject! {|k,v| v.nil? }
      { props: props.each { |k, v|  props[k] = create_escape_value(v) } }
    end

    # Stolen from keymaker
    # https://github.com/therubymug/keymaker/blob/master/lib/keymaker/parsers/cypher_response_parser.rb
    def self.translate_response(response_body, result)
      Hashie::Mash.new(Hash[sanitized_column_names(response_body).zip(result)])
    end

    def self.sanitized_column_names(response_body)
      response_body.columns.map { |column| column[/[^\.]+$/] }
    end

    def cypher_string(labels, props)
      "CREATE (n#{label_string(labels)} #{prop_identifier(props)}) RETURN ID(n)"
    end

    def label_string(labels)
      labels.empty? ? '' : ":#{labels.map{|k| "`#{k}`"}.join(':')}"
    end

    def prop_identifier(props)
      '{props}' unless props.nil?
    end
  end
end
