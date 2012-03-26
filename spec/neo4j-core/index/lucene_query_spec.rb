require 'spec_helper'

describe Neo4j::Core::Index::LuceneQuery, :type => :mock_db do

  describe "hash query" do

    let(:index) do
      mock("index")
    end

    let(:index_config) do
      Neo4j::Core::Index::IndexConfig.new(:node)
    end

    subject do
      Neo4j::Core::Index::LuceneQuery.new(index, index_config, nil)
    end

    context "when field_type is String" do
      it "constructs a term query" do
        index_config.index([:name])
        boolean_query = subject.send(:build_hash_query, :name => 'andreas')

        clauses = boolean_query.clauses
        clauses.size.should == 1
        clause = clauses[0]
        clause.should be_a(Java::OrgApacheLuceneSearch::BooleanClause)
        clause.should be_required
        query = clause.query
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
          boolean_query = subject.send(:build_hash_query, :size => 42)

          clauses = boolean_query.clauses
          clauses.size.should == 1
          clause = clauses[0]
          clause.should be_a(Java::OrgApacheLuceneSearch::BooleanClause)
          clause.should be_required
          query = clause.query
          query.should be_a(Java::OrgApacheLuceneSearch::NumericRangeQuery)
          query.max.should == 42
          query.min.should == 42
        end
      end

      describe "range query :size => (5..42)" do
        it "constructs a fixnum numeric range query with different min and max" do
          index_config.index([:size, {:field_type => Fixnum}])
          boolean_query = subject.send(:build_hash_query, :size => (5..41))

          clauses = boolean_query.clauses
          clauses.size.should == 1
          clause = clauses[0]
          clause.should be_a(Java::OrgApacheLuceneSearch::BooleanClause)
          clause.should be_required
          query = clause.query
          query.should be_a(Java::OrgApacheLuceneSearch::NumericRangeQuery)
          query.max.should == 41
          query.min.should == 5
        end
      end
    end
  end

end