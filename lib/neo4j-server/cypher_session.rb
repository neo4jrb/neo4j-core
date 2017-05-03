require 'uri'

module Neo4j
  module Server
    Neo4j::Session.register_db(:server_db) do |endpoint_url, url_opts|
      Neo4j::Server::CypherSession.open(endpoint_url, url_opts)
    end

    class CypherSession < Neo4j::Session
      include Resource

      alias super_query query
      attr_reader :connection

      def initialize(data_url, connection)
        @connection = connection
        Neo4j::Session.register(self)
        initialize_resource(data_url)
        Neo4j::Session._notify_listeners(:session_available, self)
      end

      # @param [Hash] params could be empty or contain basic authentication user and password
      # @return [Faraday]
      # @see https://github.com/lostisland/faraday
      def self.create_connection(params, url = nil)
        init_params = params[:initialize] && params.delete(:initialize)
        conn = Faraday.new(url, init_params) do |b|
          b.request :basic_auth, params[:basic_auth][:username], params[:basic_auth][:password] if params[:basic_auth]
          b.request :multi_json
          # b.response :logger, ::Logger.new(STDOUT), bodies: true

          b.response :multi_json, symbolize_keys: true, content_type: 'application/json'
          # b.use Faraday::Response::RaiseError
          require 'typhoeus'
          require 'typhoeus/adapters/faraday'
          b.adapter :typhoeus
          # b.adapter  Faraday.default_adapter
        end
        conn.headers = {'Content-Type' => 'application/json', 'User-Agent' => ::Neo4j::Session.user_agent_string}
        conn
      end

      # Opens a session to the database
      # @see Neo4j::Session#open
      #
      # @param [String] endpoint_url - the url to the neo4j server, defaults to 'http://localhost:7474'
      # @param [Hash] params faraday params, see #create_connection or an already created faraday connection
      def self.open(endpoint_url = nil, params = {})
        extract_basic_auth(endpoint_url, params)
        url = endpoint_url || 'http://localhost:7474'
        connection = params[:connection] || create_connection(params, url)
        response = connection.get(url)
        fail "Server not available on #{url} (response code #{response.status})" unless response.status == 200
        establish_session(response.body, connection)
      end

      def self.establish_session(root_data, connection)
        data_url = root_data[:data]
        data_url << '/' unless data_url.nil? || data_url.end_with?('/')
        CypherSession.new(data_url, connection)
      end

      def self.extract_basic_auth(url, params)
        return unless url && URI(url).userinfo
        params[:basic_auth] = {username: URI(url).user, password: URI(url).password}
      end

      private_class_method :extract_basic_auth

      def db_type
        :server_db
      end

      def to_s
        "#{self.class} url: '#{@resource_url}'"
      end

      def inspect
        "#{self} version: '#{version}'"
      end

      def version
        resource_data ? resource_data[:neo4j_version] : ''
      end

      def initialize_resource(data_url)
        response = @connection.get(data_url)
        expect_response_code!(response, 200)
        data_resource = response.body
        fail "No data_resource for #{response.body}" unless data_resource
        # store the resource data
        init_resource_data(data_resource, data_url)
      end

      def self.transaction_class
        Neo4j::Server::CypherTransaction
      end

      # Duplicate of CypherSession::Adaptor::Base#transaction
      def transaction
        return self.class.transaction_class.new(self) if !block_given?

        begin
          tx = transaction

          yield tx
        rescue Exception => e # rubocop:disable Lint/RescueException
          tx.mark_failed

          raise e
        ensure
          tx.close
        end
      end

      def create_node(props = nil, labels = [])
        label_string = labels.empty? ? '' : (':' + labels.map { |k| "`#{k}`" }.join(':'))
        if !props.nil?
          prop = '{props}'
          props.each_key { |k| props.delete(k) if props[k].nil? }
        end

        id = _query_or_fail("CREATE (n#{label_string} #{prop}) RETURN ID(n)", true, props: props)
        CypherNode.new(self, props.nil? ? id : {id: id, metadata: {labels: labels}, data: props})
      end

      def load_node(neo_id)
        query.unwrapped.match(:n).where(n: {neo_id: neo_id}).pluck(:n).first
      end

      def load_relationship(neo_id)
        query.unwrapped.optional_match('(n)-[r]-()').where(r: {neo_id: neo_id}).pluck(:r).first
      rescue Neo4j::Session::CypherError => cypher_error
        return nil if cypher_error.message =~ /not found$/

        raise cypher_error
      end

      def create_label(name)
        CypherLabel.new(self, name)
      end

      def uniqueness_constraints(label)
        schema_properties("/db/data/schema/constraint/#{label}/uniqueness")
      end

      def indexes(label)
        schema_properties("/db/data/schema/index/#{label}")
      end

      def schema_properties(query_string)
        response = @connection.get(query_string)
        expect_response_code!(response, 200)
        {property_keys: response.body.map! { |row| row[:property_keys].map(&:to_sym) }}
      end

      def find_all_nodes(label_name)
        search_result_to_enumerable_first_column(_query_or_fail("MATCH (n:`#{label_name}`) RETURN ID(n)"))
      end

      def find_nodes(label_name, key, value)
        value = "'#{value}'" if value.is_a? String

        response = _query_or_fail("MATCH (n:`#{label_name}`) WHERE n.#{key} = #{value} RETURN ID(n)")
        search_result_to_enumerable_first_column(response)
      end

      def query(*args)
        if [[String], [String, Hash]].include?(args.map(&:class))
          response = _query(*args)
          response.raise_error if response.error?
          response.to_node_enumeration(args[0])
        else
          options = args[0] || {}
          Neo4j::Core::Query.new(options.merge(session: self))
        end
      end

      def _query_data(query)
        r = _query_or_fail(query, true)
        Neo4j::Transaction.current ? r : r[:data]
      end

      DEFAULT_RETRY_COUNT = ENV['NEO4J_RETRY_COUNT'].nil? ? 10 : ENV['NEO4J_RETRY_COUNT'].to_i

      def _query_or_fail(query, single_row = false, params = {}, retry_count = DEFAULT_RETRY_COUNT)
        query, params = query_and_params(query, params)

        response = _query(query, params)
        if response.error?
          _retry_or_raise(query, params, single_row, retry_count, response)
        else
          single_row ? response.first_data : response
        end
      end

      def query_and_params(query_or_query_string, params)
        if query_or_query_string.is_a?(::Neo4j::Core::Query)
          cypher = query_or_query_string.to_cypher
          [cypher, query_or_query_string.send(:merge_params).merge(params)]
        else
          [query_or_query_string, params]
        end
      end

      def _retry_or_raise(query, params, single_row, retry_count, response)
        response.raise_error unless response.retryable_error?
        retry_count > 0 ? _query_or_fail(query, single_row, params, retry_count - 1) : response.raise_error
      end

      def _query_entity_data(query, id = nil, params = {})
        _query(query, params).tap(&:raise_if_cypher_error!).entity_data(id)
      end

      def _query(query, params = {}, options = {})
        query, params = query_and_params(query, params)

        ActiveSupport::Notifications.instrument('neo4j.cypher_query', params: params, context: options[:context],
                                                                      cypher: query, pretty_cypher: options[:pretty_cypher]) do
          if current_transaction
            current_transaction._query(query, params)
          else
            query = params.nil? ? {'query' => query} : {'query' => query, 'params' => params}
            response = @connection.post(resource_url(:cypher), query)
            CypherResponse.create_with_no_tx(response)
          end
        end
      end

      def search_result_to_enumerable_first_column(response)
        return [] unless response.data

        Enumerator.new do |yielder|
          response.data.each do |data|
            if current_transaction
              data[:row].each do |id|
                yielder << CypherNode.new(self, id).wrapper
              end
            else
              yielder << CypherNode.new(self, data[0]).wrapper
            end
          end
        end
      end

      def current_transaction
        Neo4j::Transaction.current_for(self)
      end

      EMPTY = ''
      NEWLINE_W_SPACES = "\n  "
      def self.log_with
        ActiveSupport::Notifications.subscribe('neo4j.cypher_query') do |_, start, finish, _id, payload|
          ms = (finish - start) * 1000
          params_string = (payload[:params] && !payload[:params].empty? ? "| #{payload[:params].inspect}" : EMPTY)
          cypher = payload[:pretty_cypher] ? NEWLINE_W_SPACES + payload[:pretty_cypher].gsub(/\n/, NEWLINE_W_SPACES) : payload[:cypher]

          yield(" #{ANSI::CYAN}#{payload[:context] || 'CYPHER'}#{ANSI::CLEAR} #{ANSI::YELLOW}#{ms.round}ms#{ANSI::CLEAR} #{cypher} #{params_string}")
        end
      end
    end
  end
end
