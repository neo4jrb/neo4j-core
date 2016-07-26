module Helpers
  def create_embedded_session
    Neo4j::Session.open(:impermanent_db, EMBEDDED_DB_PATH, auto_commit: true)
  end

  def server_username
    ENV['NEO4J_USERNAME'] || 'neo4j'
  end

  def server_password
    ENV['NEO4J_PASSWORD'] || 'neo4jrb rules, ok?'
  end

  def basic_auth_hash
    if server_uri.user && server_uri.password
      {
        username: server_uri.user,
        password: server_uri.password
      }
    else
      {
        username: server_username,
        password: server_password
      }
    end
  end

  def server_url
    ENV['NEO4J_URL'] || 'http://localhost:7474'
  end

  def server_uri
    @server_uri ||= URI(server_url)
  end

  def create_appropriate_session
    defined?(Neo4j::Community) && RUBY_PLATFORM == 'java' ? create_embedded_session.start : create_server_session
  end

  def create_server_session(options = {})
    Neo4j::Session.open(:server_db, server_url, basic_auth_hash.merge!(options))
  end

  def create_named_server_session(name, default = nil)
    Neo4j::Session.open(:server_db, server_url, basic_auth: basic_auth_hash, name: name, default: default)
  end

  def session
    Neo4j::Session.current
  end

  def current_session
    Neo4j::Session.current
  end

  def unique_random_number
    "#{Time.now.year}#{Time.now.to_i}#{Time.now.usec.to_s[0..2]}".to_i
  end

  def delete_db
    session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n, r')
  end

  def delete_schema(session = nil)
    Neo4j::Core::Label.drop_uniqueness_constraints_for(session || current_session)
    Neo4j::Core::Label.drop_indexes_for(session || current_session)
  end

  def create_constraint(session, label_name, property, options = {})
    label_object = Neo4j::Core::Label.new(label_name, session)
    label_object.create_constraint(property, options)
  end

  def create_index(session, label_name, property, options = {})
    label_object = Neo4j::Core::Label.new(label_name, session)
    label_object.create_index(property, options)
  end
end
