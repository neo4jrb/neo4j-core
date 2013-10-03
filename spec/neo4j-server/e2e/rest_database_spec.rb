#require 'spec_helper'
#
#describe Neo4j::CypherDatabase do
#  before do
#    Neo4j::CypherDatabase.default_session = nil
#  end
#
#  describe 'connect' do
#    let(:created_session) do
#      Neo4j::CypherDatabase.connect(TEST_DATABASE_URL)
#    end
#
#    it "creates Neo4j::Session" do
#      created_session.should be_a(Neo4j::Session)
#    end
#
#    it "raise Neo4j::ConnectionError if server does not answer" do
#      expect { Neo4j::CypherDatabase.connect("http://localhost:9912") }.to raise_error(Neo4j::ConnectionError)
#    end
#
#    it 'returns a session with an URL' do
#      created_session.url.should == TEST_DATABASE_URL
#    end
#
#    it 'stores the session as the default_session' do
#      session = Neo4j::CypherDatabase.connect("http://localhost:7474")
#      Neo4j::CypherDatabase.default_session.should == session
#    end
#
#    it 'creates an session with given configuration' do
#      session = Neo4j::CypherDatabase.connect(TEST_DATABASE_URL, config: {foo: :bar})
#      session.config[:foo].should == :bar
#    end
#  end
#end
#
#describe Neo4j::Session do
#
#  describe 'create_node' do
#    let(:session) { Neo4j::CypherDatabase.connect(TEST_DATABASE_URL) }
#
#    it 'can create a node without properties' do
#      node = session.create_node
#      node.should be_a(Neo4j::Node)
#      node.props.should == {}
#    end
#
#    it 'can create a node with properties' do
#      node = session.create_node(name: 'kalle')
#      node.should be_a(Neo4j::Node)
#      node.props.should == {name: 'kalle'}
#    end
#
#    it 'can create a node with labels' do
#      node = session.create_node({}, :person)
#      node.labels.should == [:person]
#    end
#
#    it 'will have an _id method' do
#      node = session.create_node
#      node._id.should be_a(Fixnum)
#    end
#  end
#
#end
#
#describe 'create_label' do
#  let(:session) { Neo4j::CypherDatabase.connect(TEST_DATABASE_URL) }
#
#  it 'has a name' do
#    label = session.create_label(:foo1)
#    label.name.should == :foo1
#  end
#
#  it 'can have an index' do
#    label = session.create_label(:foo2)
#    index = label.create_index(:name)
#    index.properties.should == [:name]
#  end
#
#  it 'knows which indexes it has' do
#    label = session.create_label(:foo3)
#    label.indexes = [:name]
#  end
#
#  it 'can drop an index' do
#    label = session.create_label(:foo4)
#    label.indexes = [:name]
#    label.drop_index(:name)
#    label.index.should == []
#  end
#end
#
#describe 'create_tx' do
#  let(:session) { Neo4j::CypherDatabase.connect(TEST_DATABASE_URL) }
#
#  it 'creates transaction which has an exec url and commit url' do
#    tx = session.create_tx
#    tx.exec_url.should be_a(String)
#    tx.commit_url.should be_a(String)
#  end
#
#  it 'is alive when created' do
#    tx = session.create_tx
#    tx.alive?.should be_true
#  end
#
#  it 'can be used to execute queries' do
#    tx = session.create_tx
#    response = tx.exec_query("START n=node(0) RETURN n")
#    response.code.should == 200
#    response
#  end
#
#
#  #label = session.create_label
#  #label.create_index(:name)
#  #
#  #session.create_node({name: 'kalle'}, labels)
#  #
#  #
#  #tx = session.create_tx
#  #tx.fail
#  #tx.finish
#  #
#  #
#  #session.create_tx do
#  #
#  #end
#  #
#  #session.config.node_identity = {property: :_id} # :internal
#  #
#  #
#  #session.create_node(properties: {name: 'kalle'}, labels: [:foo], unique: [:name])  # is same as Neo4j::Node.create(properties: {name: 'kalle'}, session: session)
#  #session.create_rel(from: node1, to: node2, properties: {})  # is same as Neo4j::Relationship.create(properties: {name: 'kalle'}, session: session)
#end
#
#describe Neo4j::CypherDatabase do
#  #describe '_query' do
#  #  before(:all) do
#  #    @session = Neo4j::CypherDatabase.connect("http://localhost:7474")
#  #  end
#  #
#  #  after(:all) do
#  #    @session.finish
#  #  end
#  #
#  #
#  #  describe 'without tx' do
#  #    it 'dsa' do
#  #
#  #    end
#  #  end
#  #end
#end