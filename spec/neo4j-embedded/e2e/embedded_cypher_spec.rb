require 'spec_helper'

describe 'Embedded Cypher Response', api: :embedded do
  it 'does not raise an error when no return is given' do
    expect { Neo4j::Session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n') }.not_to raise_error
  end
end
