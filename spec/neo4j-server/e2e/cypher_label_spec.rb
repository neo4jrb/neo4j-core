require 'spec_helper'

describe 'label', api: :server do

  it_behaves_like "Neo4j::Label"

  describe 'query' do
    before(:all) do
      r = Random.new
      @label = ("R3" + r.rand(0..1000000).to_s).to_sym
      @kalle = Neo4j::Node.create({name: 'kalle', age: 4}, @label)
      @andreas = Neo4j::Node.create({name: 'andreas', age: 2}, @label)
      @andreas = Neo4j::Node.create({name: 'andreas', age: 1}, @label)
      @zebbe = Neo4j::Node.create({name: 'zebbe', age: 3}, @label)
    end

    it 'sorts with: order: :name' do
      result = Neo4j::Label.query(@label, order: :name)
      result.count.should == 4
      result.to_a.map{|n| n[:name]}.should == %w[andreas andreas kalle zebbe]
    end

    it 'sorts with: order: [:name, :age]' do
      result = Neo4j::Label.query(@label, order: [:name, :age])
      result.count.should == 4
      result.map{|n| n[:name]}.should == %w[andreas andreas kalle zebbe]
      result.map{|n| n[:age]}.should == [1,2,4,3]
    end

    it 'sorts with: order: [:name, :age]' do
      result = Neo4j::Label.query(@label, order: [:name, :age])
      result.count.should == 4
      result.map{|n| n[:name]}.should == %w[andreas andreas kalle zebbe]
      result.map{|n| n[:age]}.should == [1,2,4,3]
    end

    it 'sorts with order: {name: :desc}' do
      result = Neo4j::Label.query(@label, order: {name: :desc})
      result.map{|n| n[:name]}.should == %w[zebbe kalle andreas andreas]

      result = Neo4j::Label.query(@label, order: {name: :asc})
      result.map{|n| n[:name]}.should == %w[andreas andreas kalle zebbe]
    end

    it 'sorts with order: [:name, {age: :desc}]' do
      result = Neo4j::Label.query(@label, order: [:name, {age: :desc}])
      result.map{|n| n[:name]}.should == %w[andreas andreas kalle zebbe]
      result.map{|n| n[:age]}.should == [2,1,4,3]

      result = Neo4j::Label.query(@label, order: [:name, {age: :asc}])
      result.map{|n| n[:name]}.should == %w[andreas andreas kalle zebbe]
      result.map{|n| n[:age]}.should == [1,2,4,3]
    end

  end

end