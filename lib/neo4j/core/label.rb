module Neo4j
  module Core
    class Label
      attr_reader :name

      def initialize(name, session)
        @name = name
        @session = session
        schema_threads = []
      end

      def create_index(property, options = {})
        validate_index_options!(options)
        properties = property.is_a?(Array) ? property.join(',') : property
        schema_query("CREATE INDEX ON :`#{@name}`(#{properties})")
      end

      def drop_index(property, options = {})
        validate_index_options!(options)
        schema_query("DROP INDEX ON :`#{@name}`(#{property})")
      end

      # Creates a neo4j constraint on a property
      # See http://docs.neo4j.org/chunked/stable/query-constraints.html
      # @example
      #   label = Neo4j::Label.create(:person, session)
      #   label.create_constraint(:name, {type: :unique}, session)
      #
      def create_constraint(property, constraints)
        cypher = case constraints[:type]
                 when :unique
                   "CREATE CONSTRAINT ON (n:`#{name}`) ASSERT n.`#{property}` IS UNIQUE"
                 else
                   fail "Not supported constrain #{constraints.inspect} for property #{property} (expected :type => :unique)"
                 end
        schema_query(cypher)
      end

      # Drops a neo4j constraint on a property
      # See http://docs.neo4j.org/chunked/stable/query-constraints.html
      # @example
      #   label = Neo4j::Label.create(:person, session)
      #   label.create_constraint(:name, {type: :unique}, session)
      #   label.drop_constraint(:name, {type: :unique}, session)
      #
      def drop_constraint(property, constraint)
        cypher = case constraint[:type]
                 when :unique
                   "DROP CONSTRAINT ON (n:`#{name}`) ASSERT n.`#{property}` IS UNIQUE"
                 else
                   fail "Not supported constrain #{constraint.inspect}"
                 end
        schema_query(cypher)
      end

      def indexes
        @session.indexes_for_label(@name)
      end

      def self.indexes_for(session)
        session.all_indexes
      end

      def drop_indexes
        indexes.each do |index|
          begin
            @session.query("DROP INDEX ON :`#{name}`(#{index})")
          rescue Neo4j::Server::CypherResponse::ResponseError
            # This will error on each constraint. Ignore and continue.
            next
          end
        end
      end

      def self.drop_indexes_for(session)
        indexes_for(session).each do |label, indexes|
          begin
            indexes.each do |index|
              session.query("DROP INDEX ON :`#{label}`(#{index[0]})")
            end
          rescue Neo4j::Server::CypherResponse::ResponseError
            # This will error on each constraint. Ignore and continue.
            next
          end
        end
      end

      def index?(property)
        indexes.include?([property])
      end

      def uniqueness_constraints
        @session.uniqueness_constraints_for_label(@name)
      end

      def drop_uniqueness_constraints
        uniqueness_constraints.each do |constraint|
          @session.query("DROP CONSTRAINT ON (n:`#{name}`) ASSERT n.`#{constraint}` IS UNIQUE")
        end
      end

      def self.drop_uniqueness_constraints_for(session)
        session.all_uniqueness_constraints.each do |label, constraints|
          constraints.each do |constraint|
            session.query("DROP CONSTRAINT ON (n:`#{label}`) ASSERT n.`#{constraint[0]}` IS UNIQUE")
          end
        end
      end

      def uniqueness_constraint?(property)
        uniqueness_constraints.include?(property)
      end

      def self.wait_for_schema_changes(session)
        schema_threads(session).map(&:join)
        set_schema_threads(session, [])
      end

      private

      # Store schema threads on the session so that we can easily wait for all
      # threads on a session regardless of label
      def schema_threads
        self.class.schema_threads(@session)
      end

      def schema_threads=(array)
        self.class.set_schema_threads(@session, array)
      end

      def self.schema_threads(session)
        session.instance_variable_get('@_schema_threads') || []
      end

      def self.set_schema_threads(session, array)
        session.instance_variable_set('@_schema_threads', array)
      end

      # Schema queries can run separately from other queries, but they should
      # be mutually exclusive to each other or we get locking errors
      SCHEMA_QUERY_SEMAPHORE = Mutex.new

      # If there is a transaction going on, this could block
      # So we run in a thread and it will go through at the next opportunity
      def schema_query(cypher)
        Thread.new do
          SCHEMA_QUERY_SEMAPHORE.synchronize do
            begin
              tx = @session.adaptor.class.transaction_class.new(@session)

              tx.query(cypher, {}, do_not_wait_for_schema_changes: true)
            rescue Exception => e
              puts 'ERROR during schema query:'
              puts e.message
              puts e.backtrace
              tx.mark_failed
            ensure
              tx.close
            end
          end
        end.tap do |thread|
          schema_threads << thread
        end
      end

      def validate_index_options!(options)
        return unless options[:type] && options[:type] != :exact
        fail "Type #{options[:type]} is not supported"
      end
    end
  end
end
