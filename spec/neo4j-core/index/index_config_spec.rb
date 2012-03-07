require 'spec_helper'

describe Neo4j::Core::Index::IndexConfig do

  subject { Neo4j::Core::Index::IndexConfig.new(:node) }

  context "trigger_on :_classname => [Foo, Bar]" do
    before do
      subject.trigger_on :_classname => %w[Foo Bar]
    end

    it "should set the _trigger_on attribute" do
      subject._trigger_on['_classname'].should include('Foo', 'Bar')
    end

    describe "trigger_on?" do
      its(:trigger_on?, {'_classname' => 'FooBar'}) { should be_false }
      its(:trigger_on?, {'_classname' => 'Bar'}) { should be_true }
      its(:trigger_on?, {'_classname' => 'Foo'}) { should be_true }
    end

    describe "trigger_on is called again with an array" do
      it "should merge the arrays" do
        subject.trigger_on :_classname => %w[Hoho Haha], :itype => %w[ajaj]
        subject._trigger_on['itype'].should include('ajaj')
        subject._trigger_on['_classname'].should include('Foo','Bar', 'Hoho', 'Haha')
        subject._trigger_on['_classname'].size.should == 4
      end
    end

    describe "trigger_on is called again with a String" do
      it "should merge the arrays" do
        subject.trigger_on :_classname => 'hoj', :itype => 'ojoj'
        subject._trigger_on['itype'].should include('ojoj')
        subject._trigger_on['_classname'].should include('Foo','Bar', 'hoj')
        subject._trigger_on['_classname'].size.should == 3
      end
    end

  end
end