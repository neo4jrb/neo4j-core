module Neo4j
  module Server
    class CypherNode < Neo4j::Node
      include Neo4j::Server::Resource
      include Neo4j::Core::ActiveEntity

      MARSHAL_INSTANCE_VARIABLES = %i[@props @labels @neo_id]

      def initialize(session, value)
        @session = session

        @neo_id = if value.is_a?(Hash)
                    @props = value[:data]
                    @labels = value[:metadata][:labels].map!(&:to_sym) if value[:metadata]
                    value[:id]
                  else
                    value
                  end
      end

      attr_reader :neo_id

      def inspect
        "CypherNode #{neo_id} (#{object_id})"
      end

      # TODO, needed by neo4j-cypher
      def _java_node
        self
      end

      # (see Neo4j::Node#create_rel)
      def create_rel(type, other_node, props = nil)
        q = @session.query.match(:a, :b).where(a: {neo_id: neo_id}, b: {neo_id: other_node.neo_id})
                    .create("(a)-[r:`#{type}`]->(b)").break.set(r: props).return(r: :neo_id)

        id = @session._query_or_fail(q, true)

        CypherRelationship.new(@session, type: type, data: props, start: neo_id, end: other_node.neo_id, id: id)
      end

      # (see Neo4j::Node#props)
      def props
        if @props
          @props
        else
          hash = @session._query_entity_data(match_start_query.return(:n), nil)
          @props = Hash[hash[:data].to_a]
        end
      end

      def refresh
        @props = nil
      end

      # (see Neo4j::Node#remove_property)
      def remove_property(key)
        refresh
        @session._query_or_fail(match_start_query.remove(n: key), false)
      end

      # (see Neo4j::Node#set_property)
      def set_property(key, value)
        refresh
        @session._query_or_fail(match_start_query.set(n: {key => value}), false)
      end

      # (see Neo4j::Node#props=)
      def props=(properties)
        refresh
        @session._query_or_fail(match_start_query.set_props(n: properties), false)
        properties
      end

      def remove_properties(properties)
        return if properties.empty?

        refresh
        @session._query_or_fail(match_start_query.remove(n: properties), false, neo_id: neo_id)
      end

      # (see Neo4j::Node#update_props)
      def update_props(properties)
        refresh
        return if properties.empty?

        @session._query_or_fail(match_start_query.set(n: properties), false)

        properties
      end

      # (see Neo4j::Node#get_property)
      def get_property(key)
        @props ? @props[key.to_sym] : @session._query_or_fail(match_start_query.return(n: key), true)
      end

      # (see Neo4j::Node#labels)
      def labels
        @labels ||= @session._query_or_fail(match_start_query.return('labels(n) AS labels'), true).map(&:to_sym)
      end

      def _cypher_label_list(labels_list)
        ':' + labels_list.map { |label| "`#{label}`" }.join(':')
      end

      def add_label(*new_labels)
        @session._query_or_fail(match_start_query.set(n: new_labels), false)
        new_labels.each { |label| labels << label }
      end

      def remove_label(*target_labels)
        @session._query_or_fail(match_start_query.remove(n: target_labels), false)
        target_labels.each { |label| labels.delete(label) } unless labels.nil?
      end

      def set_label(*label_names)
        labels_to_add = label_names.map(&:to_sym).uniq
        labels_to_remove = labels - label_names

        common_labels = labels & labels_to_add
        labels_to_add -= common_labels
        labels_to_remove -= common_labels

        query = _set_label_query(labels_to_add, labels_to_remove)
        @session._query_or_fail(query, false) unless (labels_to_add + labels_to_remove).empty?
      end

      def _set_label_query(labels_to_add, labels_to_remove)
        query = match_start_query
        query = query.remove(n: labels_to_remove) unless labels_to_remove.empty?
        query = query.set(n: labels_to_add) unless labels_to_add.empty?
        query
      end

      # (see Neo4j::Node#del)
      def del
        query = match_start_query.optional_match('(n)-[r]-()').delete(:n, :r)
        @session._query_or_fail(query, false)
      end

      alias delete del
      alias destroy del

      # (see Neo4j::Node#exist?)
      def exist?
        !@session._query(match_start_query.return(n: :neo_id)).data.empty?
      end

      # (see Neo4j::Node#node)
      def node(match = {})
        ensure_single_relationship { match(CypherNode, 'p as result LIMIT 2', match) }
      end

      # (see Neo4j::Node#rel)
      def rel(match = {})
        ensure_single_relationship { match(CypherRelationship, 'r as result LIMIT 2', match) }
      end

      # (see Neo4j::Node#rel?)
      def rel?(match = {})
        result = match(CypherRelationship, 'r as result', match)
        !!result.first
      end

      # (see Neo4j::Node#nodes)
      def nodes(match = {})
        match(CypherNode, 'p as result', match)
      end

      # (see Neo4j::Node#rels)
      def rels(match = {dir: :both})
        match(CypherRelationship, 'r as result', match)
      end

      # @private
      def match(clazz, returns, match = {})
        ::Neo4j::Node.validate_match!(match)

        query = self.query

        query = query.match(:p).where(p: {neo_id: match[:between].neo_id}) if match[:between]

        r = query.match("(n)#{relationship_arrow(match)}(p)").return(returns).response

        r.raise_error if r.error?

        r.to_node_enumeration.map(&:result)
      end

      def query(identifier = :n)
        @session.query.match(identifier).where(identifier => {neo_id: neo_id})
      end

      private

      DEFAULT_RELATIONSHIP_ARROW_DIRECTION = :both
      def relationship_arrow(match)
        rel_spec = match[:type] ? "[r:`#{match[:type]}`]" : '[r]'

        case match[:dir] || DEFAULT_RELATIONSHIP_ARROW_DIRECTION
        when :outgoing then "-#{rel_spec}->"
        when :incoming then "<-#{rel_spec}-"
        when :both then "-#{rel_spec}-"
        else
          fail "Invalid value for relationship_arrow direction: #{match[:dir].inspect}"
        end
      end

      def ensure_single_relationship
        fail 'Expected a block' unless block_given?
        result = yield
        fail "Expected to only find one relationship from node #{neo_id} matching #{match.inspect} but found #{result.count}" if result.count > 1
        result.first
      end

      def match_start_query(identifier = :n)
        @session.query.match(identifier).where(identifier => {neo_id: neo_id}).with(identifier)
      end
    end
  end
end
