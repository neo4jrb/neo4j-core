require 'spec_helper'

describe Neo4j::Config do

  describe "#to_hash" do
    it "returns a hash value of all config values" do
      Neo4j::Config.to_hash.should be_a Hash
    end
  end

  describe "#default_file" do
    it "returns the location of the configuraiton file" do
      Neo4j::Config.default_file.should =~ /config\.yml$/
    end
  end

  describe "#default_file=" do
    it "sets the location of the file" do
      old = Neo4j::Config.default_file
      Neo4j::Config.default_file = 'foobar'
      Neo4j::Config.default_file.should =~ /foobar$/
      Neo4j::Config.default_file.size.should > 7 # full path
      Neo4j::Config.default_file = old
    end
  end


  describe "#defaults" do
    it "returns the default config" do
      Neo4j::Config.defaults.should be_a(Hash)
      Neo4j::Config.defaults.should include('storage_path')
    end
  end


  describe "#storage_path" do
    it "returns the full path to ['storage_path']" do
      Neo4j::Config.storage_path.should == File.expand_path('db')
    end

    it "can be changed" do
      Neo4j::Config[:qwe] = 'foo_bar'
      Neo4j::Config[:qwe].should == 'foo_bar'
    end
  end

  describe "Using string and Symbols as keys" do
    it "does not matter" do
      Neo4j::Config[:blabla] = 'foo_bar'
      Neo4j::Config["blabla"].should == 'foo_bar'

      Neo4j::Config["blabla2"] = 'foo_bar2'
      Neo4j::Config[:blabla2].should == 'foo_bar2'

      Neo4j::Config.setup.merge!(:kalle => 'foo', 'sune' => 'bar')
      Neo4j::Config[:kalle].should == 'foo'
      Neo4j::Config["kalle"].should == 'foo'
      Neo4j::Config[:sune].should == 'bar'
      Neo4j::Config["sune"].should == 'bar'
    end
  end

  describe "#to_java_map" do
    it "returns a java map" do
      Neo4j::Config.to_java_map.java_class.to_s.should == "java.util.HashMap"
      Neo4j::Config.to_java_map.size.should > 1
    end
  end

  describe "#to_hash" do
    it "returns a hash" do
      Neo4j::Config.to_hash.should be_a(Hash)
      Neo4j::Config.to_hash.size.should > 1
    end
  end
end