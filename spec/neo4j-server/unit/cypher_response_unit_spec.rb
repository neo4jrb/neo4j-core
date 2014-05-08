require 'spec_helper'

module Neo4j::Server
  describe CypherResponse do

    describe 'to_hash_enumeration' do
      it "creates a enumerable of hash key values" do
          #result.data.should == [[0]]
          #result.columns.should == ['ID(n)']
        response = CypherResponse.new(nil,nil)
        response.set_data([[0]], ['ID(n)'])

        response.to_hash_enumeration.to_a.should == [{:'ID(n)' => 0}]
      end

      it "creates an enumerable of hash key multiple values" do
        response = CypherResponse.new(nil,nil)
        response.set_data([['Romana', 126],['The Doctor',750]], ['name', 'age'])

        response.to_hash_enumeration.to_a.should ==
          [{:name => 'Romana', :age => 126},{:name => 'The Doctor', :age => 750}]
      end
    end
  end

end
