module Neo4j::Server
  class RestNode < Neo4j::Node
    include Neo4j::Server::Resource
    include Neo4j::Server::RestEntity

    def initialize(db, response, url)
      @db = db
      init_resource_data(response, url)
    end

    def inspect
      "RestNode #{neo_id} (#{object_id})"
    end

    def add_label(*labels)
      url = resource_url('labels')
      response = HTTParty.post(url, body: labels.to_json)
      expect_response_code(response, 201)
      response
    end

    def create_rel(type, other_node, props = nil)
      payload = {to: other_node.resource_url, type: type}
      payload[:data] = props if props
      wrap_resource(@db, 'create_relationship', RestRelationship, nil, :post, payload.to_json)
    end

    def rels(match = {})
      url = resource_url_for_rels(match[:dir] || :both)
      url += "/#{match[:type]}" if match[:type]

      response = HTTParty.get(url, headers: resource_headers)
      expect_response_code(response, 200, "Can't find relationships")

      result = response.map {|r| RestRelationship.new(@db, r) }

      match[:between] ? filter_rels_between(result, match[:between]) : result
    end

    def filter_rels_between(rels, between)
      rels.find_all {|rel| rel.start_node == between || rel.end_node == between}
    end

    def resource_url_for_rels(dir)
      case dir
        when :both
          url = resource_url('all_relationships')
        when :incoming
          url = resource_url('incoming_relationships')
        when :outgoing
          url = resource_url('outgoing_relationships')
        else
          raise "Unknown direction #{dir}, allowed :both, :incoming or :outgoing"
      end
      url
    end

    def property_url(key)
      resource_url('property', key: key)
    end
  end
end

