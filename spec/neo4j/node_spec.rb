require 'spec_helper'

describe Neo4j::Node do
  it "can't call #new on it" do
    expect{Neo4j::Node.new}.to raise_error
  end
end

