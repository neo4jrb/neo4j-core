require 'spec_helper'

describe Neo4j::Node do
  describe 'new' do
    it 'throws an exception' do
      expect { Neo4j::Node.new }.to raise_error(RuntimeError)
    end
  end
end
