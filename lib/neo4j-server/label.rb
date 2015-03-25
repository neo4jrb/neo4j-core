module Neo4j
  class Label
    class << self
      def constraints(session = Neo4j::Session.current)
        session.connection.get(CONSTRAINT_PATH).body
      end

      def constraint?(label_name, property, session = Neo4j::Session.current)
        label_constraints = session.connection.get("#{CONSTRAINT_PATH}/#{label_name}").body
        !label_constraints.select { |c| c[:label] == label_name.to_s && c[:property_keys].first == property.to_s }.empty?
      end

      def indexes(session = Neo4j::Session.current)
        session.connection.get(INDEX_PATH).body
      end

      def index?(label_name, property, session = Neo4j::Session.current)
        label_indexes = session.connection.get("#{INDEX_PATH}/#{label_name}").body
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
    end
  end
end
