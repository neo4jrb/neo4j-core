module Helpers
  def clean_server_db
    resource_headers = {'Content-Type' => 'application/json', 'Accept' => 'application/json'}
    q = 'START n = node(*) OPTIONAL MATCH n-[r]-() WHERE ID(n)>0 DELETE n, r;'
    url = 'http://localhost:7474/db/data/cypher'
    response = HTTParty.post(url, headers: resource_headers, body: {query: q}.to_json)
    Neo4j::Session.set_current(nil)
    raise "can't delete database, #{response}" unless response.code == 200
  end

  def clean_embedded_db
    graph_db = Neo4j::Session.current.graph_db
    ggo = Java::OrgNeo4jTooling::GlobalGraphOperations.at(graph_db)

    tx = graph_db.begin_tx
    ggo.all_relationships.each do |rel|
      rel.delete
    end
    tx.success
    tx.finish

    tx = graph_db.begin_tx
    ggo.all_nodes.each do |node|
      node.delete
    end
    tx.success
    tx.finish
    Neo4j::Session.set_current(nil)
  end
end