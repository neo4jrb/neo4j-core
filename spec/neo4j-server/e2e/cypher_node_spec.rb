require 'spec_helper'

describe Neo4j::Server::CypherNode, api: :server do

  shared_examples 'a node with properties and id' do
    describe '#neo_id' do
      it 'is a fixnum' do
        expect(subject.neo_id).to be_a(Fixnum)
      end
    end

    describe '#props' do
      it 'contains a hash of properties' do
        expect(subject.props).to eq({name: 'Brian', hat: 'fancy'})
      end
    end
  end

  context 'with tx' do
    describe 'Neo4j::Node.create' do

      around(:example) do |example|
        tx = Neo4j::Transaction.new
        example.run
        tx.finish
      end

      subject(:created_node) do
        Neo4j::Node.create({name: 'Brian', hat: 'fancy'}, :person)
      end

      it_behaves_like "a node with properties and id"

      describe 'Neo4j::Node.load' do
        subject(:loaded_node) do
          Neo4j::Node.load(created_node.neo_id)
        end

        it_behaves_like "a node with properties and id"
      end

    end
  end

  context 'without tx' do
    describe 'Neo4j::Node.create' do
      subject(:created_node) do
        Neo4j::Node.create({name: 'Brian', hat: 'fancy'}, :person)
      end

      it_behaves_like "a node with properties and id"

      describe 'Neo4j::Node.load' do
        subject(:loaded_node) do
          Neo4j::Node.load(created_node.neo_id)
        end

        it_behaves_like "a node with properties and id"
      end
    end

  end

  xit 'works' do

    #3clean_server_db
    #@tx = Neo4j::Transaction.new

    # <struct n=CypherNode 3148 (70222548854240)>

    n = Neo4j::Node.create({name: 'Brian', hat: 'fancy'}, :person)
    #n2 = Neo4j::Node.create({name: 'Andreas', hat: 'funny'}, :person)
    puts "ID #{n.neo_id}, n.props #{n.props.inspect}"
    # result = session.query("MATCH (n) WHERE ID(n) = #{n.neo_id} RETURN ID(n)").first
    # puts "RESULT #{result.inspect}"  # RESULT #<struct n=["row", [{"hat"=>"fancy", "name"=>"Brian"}]]>
    #
    # p = Neo4j::Node.load(n.neo_id)
    # puts "P #{p.props}"
    # result = session.query("START n=node(#{n.neo_id}), n2=node(#{n2.neo_id}) RETURN n,n2").first
    # #result = session.query("MATCH(n:person) RETURN n.name AS name, n.hat as hat").first
    # puts "RESULT AGAIN #{result.inspect}"
    # expect(result.n[:name]).to eq('Brian')
    # expect(result.n[:hat]).to eq('fancy')

    # n = Neo4j::Node.create(name: 'bla')
    # hash = n.props
    # expect(hash).to eq({name: 'bla'})
     #@tx.finish

  end

  it 'handles nested transaction' do
    skip "need to simulate Placebo Transaction as done in Embedded Db"
    Neo4j::Transaction.run do
      Neo4j::Transaction.run do
        Neo4j::Node.create
      end
    end
  end

  it_behaves_like "Neo4j::Node auto tx"
  it_behaves_like "Neo4j::Node with tx"

end


##
# ROW #<struct n={"labels"=>"http://localhost:7474/db/data/node/148/labels", "outgoing_relationships"=>"http://localhost:7474/db/data/node/148/relationships/out", "data"=>{"name"=>"jimmy", "age"=>42}, "traverse"
### ---

#ROW {"row"=>[{"name"=>"Brian", "hat"=>"fancy"}]}
#ROW #<struct n=["row", [{"name"=>"Brian", "hat"=>"fancy"}]]>
#RESULT AGAIN [#<struct n=["row", [{"name"=>"jimmy", "age"=>42}]]>, #<struct n=["row", [{"name"=>"andreas", "age"=>20}]]>, #<struct n=["row", [{"name"=>"kallekula"}]]>, #<struct n=["row", [{"name"=>"Brian", "hat"=>"fancy"}]]>, #<struct n=["row", [{"nam