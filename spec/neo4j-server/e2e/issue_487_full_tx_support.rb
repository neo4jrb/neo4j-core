require 'spec_helper'

describe 'tx' do
  before do
    session || create_server_session
  end

  after do
    session && session.close
    Neo4j::Transaction.current && Neo4j::Transaction.current.close
  end

  # This will be defined in the neo4j gem
  class Neo4j::Node
    module Wrapper
      class << self
        def load_class_from_label(label_name)
          begin
            label_name.to_s.split("::").inject(Kernel) {|container, name| container.const_get(name.to_s) }
          rescue NameError
            nil
          end
        end
      end

      def self.wrap?(o)
        !!o['_classname']
      end
      def self.wrap(o)
        clazz = o['_classname']
        load_class_from_label(clazz).new(o)
      end

    end
  end

  class SomeClass
    def initialize(props)
      @props = props
    end
  end


  it 'can register a wrapper plugin so that transactions works' do
    props = {name: 'a', _classname: 'SomeClass', some_id: 'myid'}
    a = Neo4j::Node.create(props, :SomeLabel)
    nodes = Neo4j::Session.current.query("MATCH (n:`SomeLabel`) RETURN n").to_a

    expect(nodes.first.n).to be_a(Neo4j::Node)
    tx = Neo4j::Transaction.new
    nodes = Neo4j::Session.current.query("MATCH (n:`SomeLabel`) RETURN n").to_a

    expect(nodes.first.n).to be_a(SomeClass)

    tx.close
  end
end