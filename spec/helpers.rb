module Helpers

  def create_embedded_session
    Neo4j::Session.open(:impermanent_db, EMBEDDED_DB_PATH, auto_commit: true)
  end

  def create_server_session
    Neo4j::Session.open(:server_db, 'http://localhost:7474', basic_auth: {username: 'neo4j', password: 'neo4jrb rules, ok?'})
  end

  def create_named_server_session(name, default = nil)
    Neo4j::Session.open_named(:server_db, name, default, 'http://localhost:7474')
  end

  def session
    Neo4j::Session.current
  end

  def unique_random_number
    "#{Time.now.year}#{Time.now.to_i}#{Time.now.usec.to_s[0..2]}".to_i
  end

  #
  # def clean_server_db
  #   resource_headers = {'Content-Type' => 'application/json', 'Accept' => 'application/json'}
  #   q = 'START n = node(*) OPTIONAL MATCH n-[r]-() WHERE ID(n)>0 DELETE n, r;'
  #   url = 'http://localhost:7474/db/data/cypher'
  #   response = HTTParty.post(url, headers: resource_headers, body: {query: q}.to_json)
  #   Neo4j::Session.set_current(nil)
  #   raise "can't delete database, #{response}" unless response.code == 200
  # end
  #
  # def clean_embedded_db
  #   graph_db = Neo4j::Session.current.graph_db
  #   ggo = Java::OrgNeo4jTooling::GlobalGraphOperations.at(graph_db)
  #
  #   tx = graph_db.begin_tx
  #   ggo.all_relationships.each do |rel|
  #     rel.delete
  #   end
  #   tx.success
  #   tx.finish
  #
  #   tx = graph_db.begin_tx
  #   ggo.all_nodes.each do |node|
  #     node.delete
  #   end
  #   tx.success
  #   tx.finish
  #   Neo4j::Session.set_current(nil)
  # end
end
