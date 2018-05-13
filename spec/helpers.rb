module Helpers
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
end
