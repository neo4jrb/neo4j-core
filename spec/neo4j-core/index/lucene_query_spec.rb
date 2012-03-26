require 'spec_helper'

describe Neo4j::Core::Index::LuceneQuery do

  let(:index) do
    mock("index")
  end

  let(:index_config) do
    Neo4j::Core::Index::IndexConfig.new(:node)
  end

  class QueryContext
    attr_accessor :query, :_sort

    def initialize(query)
      @query = query
    end

    def sort(s)
      @_sort = s
    end

  end

  subject do
    Neo4j::Core::Index::LuceneQuery.new(index, index_config, nil)
  end


  describe "build_not_query" do
    subject do
      Neo4j::Core::Index::LuceneQuery.new(index, index_config, "age: 42")
    end

    it "creates a prohibited TermQuery" do
      s = subject.not("name: foo")
      result = s.send(:build_query)
      result.clauses.size.should == 2
      result.clauses[0].should be_a(Java::OrgApacheLuceneSearch::BooleanClause)
      result.clauses[1].should be_a(Java::OrgApacheLuceneSearch::BooleanClause)
      result.clauses[0].should be_prohibited
      result.clauses[1].should be_required
      result.clauses[0].query.should be_a(Java::OrgApacheLuceneSearch::TermQuery)
      result.clauses[1].query.should be_a(Java::OrgApacheLuceneSearch::TermQuery)
      result.clauses[0].query.term.text.should == 'foo'
      result.clauses[0].query.term.field.should == 'name'
      result.clauses[1].query.term.text.should == '42'
      result.clauses[1].query.term.field.should == 'age'
    end
  end

  describe "build_and_query" do
    subject do
      Neo4j::Core::Index::LuceneQuery.new(index, index_config, "age: 42")
    end

    describe "a String AND Query" do
      it "creates two required TermQueries" do
        s = subject.and("name: foo")
        result = s.send(:build_query)
        result.should be_a(Java::OrgApacheLuceneSearch::BooleanQuery)
        result.clauses.size.should == 2
        result.clauses[0].should be_a(Java::OrgApacheLuceneSearch::BooleanClause)
        result.clauses[1].should be_a(Java::OrgApacheLuceneSearch::BooleanClause)

        result.clauses[0].should be_required
        result.clauses[1].should be_required

        result.clauses[0].query.should be_a(Java::OrgApacheLuceneSearch::TermQuery)
        result.clauses[1].query.should be_a(Java::OrgApacheLuceneSearch::TermQuery)
        result.clauses[0].query.term.text.should == '42'
        result.clauses[0].query.term.field.should == 'age'
        result.clauses[1].query.term.text.should == 'foo'
        result.clauses[1].query.term.field.should == 'name'
      end
    end

    describe "a String/Range AND Query" do
      it "creates two required TermQueries" do
        index_config.index([:salary, {:field_type => Fixnum}])
        s = subject.and(:salary => (100..200))
        result = s.send(:build_query)
        result.should be_a(Java::OrgApacheLuceneSearch::BooleanQuery)
        result.clauses.size.should == 2
        result.clauses[0].should be_a(Java::OrgApacheLuceneSearch::BooleanClause)
        result.clauses[1].should be_a(Java::OrgApacheLuceneSearch::BooleanClause)

        result.clauses[0].should be_required
        result.clauses[1].should be_required

        result.clauses[0].query.should be_a(Java::OrgApacheLuceneSearch::TermQuery)
        result.clauses[1].query.should be_a(Java::OrgApacheLuceneSearch::BooleanQuery)
        result.clauses[0].query.term.text.should == '42'
        result.clauses[0].query.term.field.should == 'age'

        numeric_range_query = result.clauses[1].query.clauses[0]
        numeric_range_query.query.should be_a(Java::OrgApacheLuceneSearch::NumericRangeQuery)
        numeric_range_query.query.max.should == 200
        numeric_range_query.query.min.should == 100
      end
    end

    describe "a String OR Query" do
      it "creates two not required TermQueries" do
        s = subject.or("name: foo")
        result = s.send(:build_query)
        result.should be_a(Java::OrgApacheLuceneSearch::BooleanQuery)
        result.clauses.size.should == 2
        result.clauses[0].should be_a(Java::OrgApacheLuceneSearch::BooleanClause)
        result.clauses[1].should be_a(Java::OrgApacheLuceneSearch::BooleanClause)

        result.clauses[0].should_not be_required
        result.clauses[1].should_not be_required

        result.clauses[0].query.should be_a(Java::OrgApacheLuceneSearch::TermQuery)
        result.clauses[1].query.should be_a(Java::OrgApacheLuceneSearch::TermQuery)
        result.clauses[0].query.term.text.should == '42'
        result.clauses[0].query.term.field.should == 'age'
        result.clauses[1].query.term.text.should == 'foo'
        result.clauses[1].query.term.field.should == 'name'
      end
    end

  end

  describe "build_sort_query" do

    describe "asc string" do
      before do
        subject.asc(:name)
        index_config.index([:name])
        Java::OrgNeo4jIndexLucene::QueryContext.stub!(:new) { |q| QueryContext.new(q) }
      end

      it "sorts by an ascending String" do
        result = subject.send(:build_sort_query, 'a query')
        result.should be_a(Java::OrgApacheLuceneSearch::Sort)
        result.sort.size.should == 1
        result.sort[0].field.should == 'name'
        result.sort[0].reverse.should be_false
        result.sort[0].type.should == Java::OrgApacheLuceneSearch::SortField::STRING
      end
    end

    describe "desc Float" do
      before do
        subject.desc(:size)
        index_config.index([:size, {:field_type => Float}])
        Java::OrgNeo4jIndexLucene::QueryContext.stub!(:new) { |q| QueryContext.new(q) }
      end

      it "sorts by an desc Float" do
        result = subject.send(:build_sort_query, 'a query')
        result.should be_a(Java::OrgApacheLuceneSearch::Sort)
        result.sort.size.should == 1
        result.sort[0].field.should == 'size'
        result.sort[0].reverse.should be_true
        result.sort[0].type.should == Java::OrgApacheLuceneSearch::SortField::DOUBLE
      end
    end

    describe "desc Fixnum and a asc String" do
      subject do
        Neo4j::Core::Index::LuceneQuery.new(index, index_config, nil, {:sort => [[:age, :desc], [:name, :asc]]})
      end

      before do
        index_config.index([:age, {:field_type => Fixnum}])
        index_config.index([:name])
        Java::OrgNeo4jIndexLucene::QueryContext.stub!(:new) { |q| QueryContext.new(q) }
      end

      it "sorts by an desc Float" do
        result = subject.send(:build_sort_query, 'a query')
        result.should be_a(Java::OrgApacheLuceneSearch::Sort)
        result.sort.size.should == 2
        result.sort[0].field.should == 'age'
        result.sort[0].reverse.should be_true
        result.sort[0].type.should == Java::OrgApacheLuceneSearch::SortField::LONG

        result.sort[1].field.should == 'name'
        result.sort[1].reverse.should be_false
        result.sort[1].type.should == Java::OrgApacheLuceneSearch::SortField::STRING
      end
    end

  end


  describe "build_hash_query" do

    def query_for_boolean_clause(query)
      clauses = query.clauses
      clauses.size.should == 1
      clause = clauses[0]
      clause.should be_a(Java::OrgApacheLuceneSearch::BooleanClause)
      clause.should be_required
      clause.query
    end

    describe ":name => 'andreas', :size => 42" do
      it "creates an boolean clause" do
        index_config.index([:name])
        index_config.index([:size, {:field_type => Fixnum}])
        result = subject.send(:build_hash_query, :name => 'andreas', :size => 31)
        clauses = result.clauses
        clauses.size.should == 2
        clause_1 = clauses[0]
        clause_1.should be_a(Java::OrgApacheLuceneSearch::BooleanClause)
        clause_1.should be_required
        clause_1.query.should be_a(Java::OrgApacheLuceneSearch::TermQuery)
        clause_1.query.term.text.should == 'andreas'
        clause_1.query.term.field.should == 'name'

        clause_2 = clauses[1]
        clause_2.query.should be_a(Java::OrgApacheLuceneSearch::NumericRangeQuery)
        clause_2.query.max.should == 31
        clause_2.query.min.should == 31
      end
    end

    context "when field_type is String" do
      it "constructs a term query" do
        index_config.index([:name])
        result = subject.send(:build_hash_query, :name => 'andreas')
        query = query_for_boolean_clause(result)

        query.should be_a(Java::OrgApacheLuceneSearch::TermQuery)
        term = query.term
        term.should be_a(Java::OrgApacheLuceneIndex::Term)
        term.text.should == "andreas"
        term.field.should == "name"
      end
    end

    context "when field_type is a Fixnum" do
      describe "exact query :size => 42" do
        it "constructs a fixnum numeric range query with same min and max" do
          index_config.index([:size, {:field_type => Fixnum}])
          result = subject.send(:build_hash_query, :size => 42)

          query = query_for_boolean_clause(result)
          query.should be_a(Java::OrgApacheLuceneSearch::NumericRangeQuery)
          query.max.should == 42
          query.min.should == 42
        end
      end

      describe "range query :size => (5..42)" do
        it "constructs a fixnum numeric range query with different min and max" do
          index_config.index([:size, {:field_type => Fixnum}])
          result = subject.send(:build_hash_query, :size => (5..41))

          query = query_for_boolean_clause(result)
          query.should be_a(Java::OrgApacheLuceneSearch::NumericRangeQuery)
          query.max.should == 41
          query.min.should == 5
        end
      end
    end

    context "when field_type is a Float" do
      describe "exact query :size => 42" do
        it "constructs a fixnum numeric range query with same min and max" do
          index_config.index([:size, {:field_type => Float}])
          result = subject.send(:build_hash_query, :size => 3.14)

          query = query_for_boolean_clause(result)
          query.should be_a(Java::OrgApacheLuceneSearch::NumericRangeQuery)
          query.max.should be_close(3.14, 0.001)
          query.min.should be_close(3.14, 0.001)
        end
      end

      describe "range query :size => (5..42)" do
        it "constructs a fixnum numeric range query with different min and max" do
          index_config.index([:size, {:field_type => Float}])
          result = subject.send(:build_hash_query, :size => (4.14..5.12))

          query = query_for_boolean_clause(result)
          query.should be_a(Java::OrgApacheLuceneSearch::NumericRangeQuery)
          query.min.should be_close(4.14, 0.001)
          query.max.should be_close(5.12, 0.001)
        end
      end
    end

  end

end