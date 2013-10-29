require 'spec_helper'


tests = Proc.new do
  before(:all) do
    Neo4j::Wrapper::Labels._wrapped_classes = []
    Neo4j::Wrapper::Labels._wrapped_labels = nil

    class TestClass
      include Neo4j::NodeMixin
    end

    Neo4j::Label.create(:IndexedTestClass).drop_index(:name)

    class IndexedTestClass
      include Neo4j::NodeMixin
      index :name  # will index using the IndexedTestClass label
    end
    #
    #module FooLabel
    #  def self.mapped_label_name
    #    "Foo" # specify the label for this module
    #  end
    #end
    #
    #module BarIndexedLabel
    #  extend Neo4j::Wrapper::LabelIndex # to make it possible to search using this module (?)
    #  index :stuff # (?)
    #end
    #
  end

  after(:all) do
    Object.send(:remove_const, :IndexedTestClass)
    Object.send(:remove_const, :TestClass)
  end

    describe 'create' do
      it "sets neo_id" do
        p = TestClass.create
        p.neo_id.should be_a(Fixnum)
      end

      it 'automatically sets a label' do
        p = TestClass.create
        p.labels.to_a.should == [:TestClass]
      end
    end

    describe 'load' do
      it 'can load a node' do
        p = TestClass.create
        id = p.neo_id
        loaded = Neo4j::Node.load(id)
        loaded.neo_id.should == id
        loaded.should == p
        #loaded.class.should == TestClass
      end
    end

    describe 'find_all' do
      it "finds it without an index" do
        p = TestClass.create
        TestClass.find_all.to_a.should include(p)
      end

      describe 'when indexed' do
        it 'can find it without using the index' do
          andreas = IndexedTestClass.create(name: 'andreas')
          result = IndexedTestClass.find_all
          result.should include(andreas)
        end

        it 'does not find it if it has been deleted' do
          jimmy = IndexedTestClass.create(name: 'jimmy')
          result = IndexedTestClass.find_all
          result.should include(jimmy)
          jimmy.del
          IndexedTestClass.find_all.should_not include(jimmy)
        end
      end
    end

  describe 'find' do
    it "finds it without an index" do
      p = TestClass.create
      TestClass.find_all.to_a.should include(p)
    end

    describe 'when indexed' do
      it 'can find it using the index' do
        kalle = IndexedTestClass.create(name: 'kalle')
        result = IndexedTestClass.find(:name, 'kalle')
        result.should include(kalle)
      end

      it 'does not find it if deleted' do
        kalle2 = IndexedTestClass.create(name: 'kalle2')
        result = IndexedTestClass.find(:name, 'kalle2')
        result.should include(kalle2)
        kalle2.del
        IndexedTestClass.find(:name, 'kalle2').should_not include(kalle2)
      end
    end

    describe 'when finding using a Module' do

    end
  end

end

describe 'Neo4j::NodeMixin', api: :server do
  self.instance_eval(&tests)
end

describe 'Neo4j::NodeMixin', api: :embedded do
  self.instance_eval(&tests)
end