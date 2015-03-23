module Neo4j
  # A label is a named graph construct that is used to group nodes.
  # See Neo4j::Node how to create and delete nodes
  # @see http://docs.neo4j.org/chunked/milestone/graphdb-neo4j-labels.html
  class Label
    class InvalidQueryError < StandardError; end

    # @abstract
    def name
      fail 'not implemented'
    end

    # @abstract
    def create_index(*properties)
      fail 'not implemented'
    end

    # @abstract
    def drop_index(*properties)
      fail 'not implemented'
    end

    # List indices for a label
    # @abstract
    def indexes
      fail 'not implemented'
    end

    # Creates a neo4j constraint on a property
    # See http://docs.neo4j.org/chunked/stable/query-constraints.html
    # @example
    #   label = Neo4j::Label.create(:person, session)
    #   label.create_constraint(:name, {type: :unique}, session)
    #
    def create_constraint(property, constraints, session = Neo4j::Session.current)
      cypher = case constraints[:type]
               when :unique
                 "CREATE CONSTRAINT ON (n:`#{name}`) ASSERT n.`#{property}` IS UNIQUE"
               else
                 fail "Not supported constrain #{constraints.inspect} for property #{property} (expected :type => :unique)"
               end
      session._query_or_fail(cypher)
    end

    # Drops a neo4j constraint on a property
    # See http://docs.neo4j.org/chunked/stable/query-constraints.html
    # @example
    #   label = Neo4j::Label.create(:person, session)
    #   label.create_constraint(:name, {type: :unique}, session)
    #   label.drop_constraint(:name, {type: :unique}, session)
    #
    def drop_constraint(property, constraint, session = Neo4j::Session.current)
      cypher = case constraint[:type]
               when :unique
                 "DROP CONSTRAINT ON (n:`#{name}`) ASSERT n.`#{property}` IS UNIQUE"
               else
                 fail "Not supported constrain #{constraint.inspect}"
               end
      session._query_or_fail(cypher)
    end

    class << self
      include Neo4j::Core::CypherTranslator
      INDEX_PATH = '/db/data/schema/index/'
      CONSTRAINT_PATH = '/db/data/schema/constraint/'

      # Returns a label of given name that can be used to specifying constraints
      # @param [Symbol,String] name the name of the label
      def create(name, session = Neo4j::Session.current)
        session.create_label(name)
      end

      def constraints(session = Neo4j::Session.current)
        session.connection.get(CONSTRAINT_PATH).body
      end

      def constraint?(label_name, property, session = Neo4j::Session.current)
        label_constraints = session.connection.get("#{CONSTRAINT_PATH}/#{label_name.to_s}").body
        !label_constraints.select { |c| c[:label] == label_name.to_s && c[:property_keys].first == property.to_s }.empty?
      end

      def indexes(session = Neo4j::Session.current)
        session.connection.get(INDEX_PATH).body
      end

      def index?(label_name, property, session = Neo4j::Session.current)
        label_indexes = session.connection.get("#{INDEX_PATH}/#{label_name.to_s}").body
        !label_indexes.select { |i| i[:label] == label_name.to_s && i[:property_keys].first == property.to_s }.empty?
      end

      def drop_all_indexes(session = Neo4j::Session.current)
        indexes.each do |i|
          begin
            session._query_or_fail("DROP INDEX ON :`#{i[:label]}`(#{i[:property_keys].first})")
          rescue Neo4j::Server::CypherResponse::ResponseError
            # This will error on each constraint. Ignore and continue.
            next
          end
        end
      end

      def drop_all_constraints(session = Neo4j::Session.current)
        constraints.each do |c|
          session._query_or_fail("DROP CONSTRAINT ON (n:`#{c[:label]}`) ASSERT n.`#{c[:property_keys].first}` IS UNIQUE")
        end
      end

      # @return [Enumerable<Neo4j::Node>] all nodes having given label. Nodes can be wrapped in your own model ruby classes.
      def find_all_nodes(label_name, session = Neo4j::Session.current)
        session.find_all_nodes(label_name)
      end

      # @return [Enumerable<Neo4j::Node>] all nodes having given label and properties. Nodes can be wrapped in your own model ruby classes.
      def find_nodes(label_name, key, value, session = Neo4j::Session.current)
        session.find_nodes(label_name, key, value)
      end
    end
  end
end
