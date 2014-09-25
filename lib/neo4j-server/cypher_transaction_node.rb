module Neo4j::Server
  class CypherTransactionNode < Neo4j::Node
    include Neo4j::Server::Resource
    include Neo4j::Core::CypherTranslator
    include Neo4j::Core::ActiveEntity

    def initialize(session, values)
      @session = session
      @props = values
    end

    def neo_id
      @neo_id ||= self_query.return("ID(result) as result_id").first.result_id
    end

    def inspect
      "CypherTransactionNode #{id_property_name}: #{delegator.id} (#{object_id})"
    end

    # TODO, needed by neo4j-cypher
    def _java_node
      self
    end

    # (see Neo4j::Node#create_rel)
    def create_rel(type, other_node, props = nil)
      # q = "START a=node(#{neo_id}), b=node(#{other_node.neo_id}) CREATE (a)-[r:`#{type}` #{cypher_prop_list(props)}]->(b) RETURN ID(r)"
      q = "MATCH (a:`#{mapped_label_name}`), (b:`#{other_node.class.mapped_label_name}`)
        CREATE (a)-[rel:`#{type}` #{cypher_prop_list(props)}]->(b)
        RETURN ID(rel)"
      id = @session._query_or_fail(q, true)
      CypherRelationship.new(@session, id, type)
    end

    def delegator=(node)
      @delegator = node
    end

    def delegator
      @delegator || (raise 'unset delegator')
    end

    def delegator_set?
      instance_variable_defined?(:@delegator)
    end

    def props
      @props
    end

    def labels
      @labels ||= delegator.class.query_as(:result).return("LABELS(result) as result_labels").first.result_labels.map(&:to_sym)
    end

    def transaction_node?
      true
    end

    def exist?
      result = self_query.return("COUNT(result) as result_count")
      result.first.result_count == 1
    end

    def id_property_name
      delegator.class.id_property_name
    end

    def id
      delegator.id
    end

    private

    def mapped_label_name
      delegator.class.mapped_label_name
    end

    def self_query
      delegator.class.query_as(:result).where("result.#{id_property_name} = '#{id}'")
    end
  end
end