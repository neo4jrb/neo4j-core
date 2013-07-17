require 'spec_helper'

describe Java::OrgNeo4jKernel::EmbeddedGraphDatabase, "lucene", :type => :java_integration do

  after(:all) do
    shutdown_embedded_db
  end

  describe "node index" do
    SUBJECT = embedded_db.index.for_nodes("MyIndex")

    def build_composite_query(left_query, right_query, operator=nil) #:nodoc:
      operator ||= Java::OrgApacheLuceneSearch::BooleanClause::Occur::MUST
      composite_query = Java::OrgApacheLuceneSearch::BooleanQuery.new
      composite_query.add(left_query, operator)
      composite_query.add(right_query, operator)
      composite_query
    end


    let(:parsed_query) do
      version = Java::OrgApacheLuceneUtil::Version::LUCENE_35
      analyzer = Java::OrgApacheLuceneAnalysisStandard::StandardAnalyzer.new(version)
      parser = Java::org.apache.lucene.queryParser.QueryParser.new(version, 'name', analyzer)
      parser.parse('name: andreas')
    end

    let(:numeric_range_query) do
      org.apache.lucene.search.NumericRangeQuery.newLongRange("age", 123, 123, true, true)
    end


    before(:all) do
      new_java_tx(embedded_db)
      NODE = embedded_db.create_node
      SUBJECT.add(NODE, "age", Java::OrgNeo4jIndexLucene::ValueContext.numeric(123.to_java(:long)))
      SUBJECT.add(NODE, "name", "andreas")
    end

    it "can get the value using the neo4j ValueContext numeric value" do
      SUBJECT.get("age", Java::OrgNeo4jIndexLucene::ValueContext.numeric(123.to_java(:long))).getSingle().should == NODE
    end

    it "can query using QueryContext numeric Range" do
      qc = Java::OrgNeo4jIndexLucene::QueryContext.numericRange("age", 123.to_java(:long), 123.to_java(:long))
      SUBJECT.query(qc).first.should == NODE
    end


    it "can query parsing a query string" do
      SUBJECT.query(parsed_query).first.should == NODE
    end

    it "can query using a org.apache.lucene.search.NumericRangeQuery" do
      SUBJECT.query(numeric_range_query).first.should == NODE
    end

    it "can create composite query using lucene BooleanQuery" do
      composite = build_composite_query(parsed_query, numeric_range_query)
      SUBJECT.query(composite).first.should == NODE
    end

  end
end

