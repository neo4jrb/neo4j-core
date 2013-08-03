require 'spec_helper'


describe "org.neo4j.graphdb.Node" do
  before(:all) do
    path = 'org.neo4j.graphdb.Node'
    # TODO use ImpermanentDatabase
    factory = Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory.new
    FileUtils.rm_rf path
    @graph_db = factory.newEmbeddedDatabase(path)
  end

  describe "getLabels()" do
    it "returns labels" do
      labelClass = Java::OrgNeo4jGraphdb::DynamicLabel
      labels = %w[foo bar].inject([]) { |result, label| result << labelClass.label(label.to_s) }.to_java(labelClass)
      tx = @graph_db.begin_tx
      node = @graph_db.create_node(labels)
      tx.success
      tx.finish
      id = node.get_id
#      puts "Created node #{node.inspect}, id #{id}"

      node2 = @graph_db.get_node_by_id(id)
#      puts "Loaded node2 #{node2}"
      label_names = node2.get_labels.map(&:name)
#      puts "labels #{label_names.join(', ')}"
      label_names.should =~ %w[foo bar]
    end
  end

  describe "getNodeById" do
    it "throws Java::OrgNeo4jGraphdb::NotFoundException if not found" do
      be_called = false
      begin
        node = @graph_db.get_node_by_id(12344)
        node.should be_nil
      rescue Java::OrgNeo4jGraphdb::NotFoundException => e
        be_called = true
#        puts "Got #{e.inspect} exception!"
      end

      be_called.should be_true
    end
  end
end