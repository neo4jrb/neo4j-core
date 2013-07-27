require 'spec_helper'

describe Neo4j::Server::CypherNode do

  class MockDatabase
    def query(*params, &query_dsl)
      _query Neo4j::Cypher.query(*params, &query_dsl).to_s
    end

    def _query(q)
    end
  end

  describe 'instance methods' do

    let(:db) { MockDatabase.new}

    describe 'exist?' do
      it "generates correct cypher" do
        db.should_receive(:_query).with('START v1=node(42) RETURN v1').and_return(Struct.new(:code).new(200))
        node = Neo4j::Server::CypherNode.new(db)
        node.init_resource_data('data', 'http://bla/42')

        # when
        node.exist?
      end

      it "returns false if HTTP 400 is received with EntityNotFoundException exception" do
        node = Neo4j::Server::CypherNode.new(db)
        node.init_resource_data('data', 'http://bla/42')

        bad_request =<<-HERE
         {
           "message" : "Node with id 42111",
           "exception" : "EntityNotFoundException",
           "fullname" : "org.neo4j.cypher.EntityNotFoundException",
           "stacktrace" : [ "org.neo4j.cypher.internal.spi.gdsimpl.TransactionBoundQueryContext$NodeOperations.getById(TransactionBoundQueryContext.scala:107)", "org.neo4j.cypher.internal.spi.gdsimpl.TransactionBoundQueryContext$NodeOperations.getById(TransactionBoundQueryContext.scala:102)", "org.neo4j.cypher.internal.spi.DelegatingOperations.getById(DelegatingQueryContext.scala:93)", "org.neo4j.cypher.internal.executionplan.builders.EntityProducerFactory$$anonfun$3$$anonfun$applyOrElse$3$$anonfun$apply$1.apply(EntityProducerFactory.scala:77)", "org.neo4j.cypher.internal.executionplan.builders.EntityProducerFactory$$anonfun$3$$anonfun$applyOrElse$3$$anonfun$apply$1.apply(EntityProducerFactory.scala:77)", "org.neo4j.cypher.internal.executionplan.builders.GetGraphElements$.org$neo4j$cypher$internal$executionplan$builders$GetGraphElements$$castElement$1(GetGraphElements.scala:30)", "org.neo4j.cypher.internal.executionplan.builders.GetGraphElements$$anonfun$getElements$3.apply(GetGraphElements.scala:40)", "scala.collection.Iterator$$anon$11.next(Iterator.scala:328)", "scala.collection.Iterator$$anon$11.next(Iterator.scala:328)", "scala.collection.Iterator$$anon$13.next(Iterator.scala:372)", "org.neo4j.cypher.internal.ClosingIterator$$anonfun$next$1.apply(ClosingIterator.scala:44)", "org.neo4j.cypher.internal.ClosingIterator.failIfThrows(ClosingIterator.scala:84)", "org.neo4j.cypher.internal.ClosingIterator.next(ClosingIterator.scala:43)", "org.neo4j.cypher.PipeExecutionResult.next(PipeExecutionResult.scala:159)", "org.neo4j.cypher.PipeExecutionResult.next(PipeExecutionResult.scala:33)", "scala.collection.Iterator$$anon$11.next(Iterator.scala:328)", "scala.collection.convert.Wrappers$IteratorWrapper.next(Wrappers.scala:30)", "org.neo4j.cypher.PipeExecutionResult$$anon$1.next(PipeExecutionResult.scala:75)", "org.neo4j.helpers.collection.ExceptionHandlingIterable$1.next(ExceptionHandlingIterable.java:67)", "org.neo4j.helpers.collection.IteratorWrapper.next(IteratorWrapper.java:47)", "org.neo4j.server.rest.repr.ListRepresentation.serialize(ListRepresentation.java:58)", "org.neo4j.server.rest.repr.Serializer.serialize(Serializer.java:75)", "org.neo4j.server.rest.repr.MappingSerializer.putList(MappingSerializer.java:61)", "org.neo4j.server.rest.repr.CypherResultRepresentation.serialize(CypherResultRepresentation.java:83)", "org.neo4j.server.rest.repr.MappingRepresentation.serialize(MappingRepresentation.java:42)", "org.neo4j.server.rest.repr.OutputFormat.assemble(OutputFormat.java:185)", "org.neo4j.server.rest.repr.OutputFormat.formatRepresentation(OutputFormat.java:133)", "org.neo4j.server.rest.repr.OutputFormat.response(OutputFormat.java:119)", "org.neo4j.server.rest.repr.OutputFormat.ok(OutputFormat.java:57)", "org.neo4j.server.rest.web.CypherService.cypher(CypherService.java:96)", "java.lang.reflect.Method.invoke(Method.java:597)", "org.neo4j.server.rest.security.SecurityFilter.doFilter(SecurityFilter.java:112)" ],
           "cause" : {
             "message" : "Node 42111 not found",
             "exception" : "NotFoundException",
             "stacktrace" : [ "org.neo4j.kernel.impl.core.NodeManager.getNodeById(NodeManager.java:342)", "org.neo4j.kernel.InternalAbstractGraphDatabase.getNodeById(InternalAbstractGraphDatabase.java:991)", "org.neo4j.cypher.internal.spi.gdsimpl.TransactionBoundQueryContext$NodeOperations.getById(TransactionBoundQueryContext.scala:108)", "org.neo4j.cypher.internal.spi.gdsimpl.TransactionBoundQueryContext$NodeOperations.getById(TransactionBoundQueryContext.scala:102)", "org.neo4j.cypher.internal.spi.DelegatingOperations.getById(DelegatingQueryContext.scala:93)", "org.neo4j.cypher.internal.executionplan.builders.EntityProducerFactory$$anonfun$3$$anonfun$applyOrElse$3$$anonfun$apply$1.apply(EntityProducerFactory.scala:77)", "org.neo4j.cypher.internal.executionplan.builders.EntityProducerFactory$$anonfun$3$$anonfun$applyOrElse$3$$anonfun$apply$1.apply(EntityProducerFactory.scala:77)", "org.neo4j.cypher.internal.executionplan.builders.GetGraphElements$.org$neo4j$cypher$internal$executionplan$builders$GetGraphElements$$castElement$1(GetGraphElements.scala:30)", "org.neo4j.cypher.internal.executionplan.builders.GetGraphElements$$anonfun$getElements$3.apply(GetGraphElements.scala:40)", "scala.collection.Iterator$$anon$11.next(Iterator.scala:328)", "scala.collection.Iterator$$anon$11.next(Iterator.scala:328)", "scala.collection.Iterator$$anon$13.next(Iterator.scala:372)", "org.neo4j.cypher.internal.ClosingIterator$$anonfun$next$1.apply(ClosingIterator.scala:44)", "org.neo4j.cypher.internal.ClosingIterator.failIfThrows(ClosingIterator.scala:84)", "org.neo4j.cypher.internal.ClosingIterator.next(ClosingIterator.scala:43)", "org.neo4j.cypher.PipeExecutionResult.next(PipeExecutionResult.scala:159)", "org.neo4j.cypher.PipeExecutionResult.next(PipeExecutionResult.scala:33)", "scala.collection.Iterator$$anon$11.next(Iterator.scala:328)", "scala.collection.convert.Wrappers$IteratorWrapper.next(Wrappers.scala:30)", "org.neo4j.cypher.PipeExecutionResult$$anon$1.next(PipeExecutionResult.scala:75)", "org.neo4j.helpers.collection.ExceptionHandlingIterable$1.next(ExceptionHandlingIterable.java:67)", "org.neo4j.helpers.collection.IteratorWrapper.next(IteratorWrapper.java:47)", "org.neo4j.server.rest.repr.ListRepresentation.serialize(ListRepresentation.java:58)", "org.neo4j.server.rest.repr.Serializer.serialize(Serializer.java:75)", "org.neo4j.server.rest.repr.MappingSerializer.putList(MappingSerializer.java:61)", "org.neo4j.server.rest.repr.CypherResultRepresentation.serialize(CypherResultRepresentation.java:83)", "org.neo4j.server.rest.repr.MappingRepresentation.serialize(MappingRepresentation.java:42)", "org.neo4j.server.rest.repr.OutputFormat.assemble(OutputFormat.java:185)", "org.neo4j.server.rest.repr.OutputFormat.formatRepresentation(OutputFormat.java:133)", "org.neo4j.server.rest.repr.OutputFormat.response(OutputFormat.java:119)", "org.neo4j.server.rest.repr.OutputFormat.ok(OutputFormat.java:57)", "org.neo4j.server.rest.web.CypherService.cypher(CypherService.java:96)", "java.lang.reflect.Method.invoke(Method.java:597)", "org.neo4j.server.rest.security.SecurityFilter.doFilter(SecurityFilter.java:112)" ],
             "fullname" : "org.neo4j.graphdb.NotFoundException"
           }
         }
        HERE

        response = Struct.new(:code, :body).new(400, bad_request)
        db.should_receive(:_query).and_return(response)

        node.exist?
      end
    end

    describe '[]=' do
      it 'generates correct cypher' do
        node = Neo4j::Server::CypherNode.new
        node.should_receive(:resource_url_id).and_return(42)
        Neo4j::Server::RestDatabase.should_receive(:_query).with('START v1=node(42) SET v1.name = "andreas" RETURN v1')
        node['name'] = 'andreas'
      end
    end

    describe '[]' do
      let(:cypher_response) do
        JSON.parse <<-HERE
        {
          "columns" : [ "n.name" ],
           "data" : [ [ "andreas" ] ]
        }
        HERE
      end

      it 'generates correct cypher' do
        node = Neo4j::Server::CypherNode.new
        node.should_receive(:resource_url_id).and_return(42)
        Neo4j::Server::RestDatabase.should_receive(:_query).with('START v1=node(42) RETURN v1.name').and_return(cypher_response)
        node['name']
      end

      it "should parse the return value from the cypher query" do
        Neo4j::Server::RestDatabase.should_receive(:_query).and_return(cypher_response)
        node = Neo4j::Server::CypherNode.new
        node.should_receive(:resource_url_id).and_return(42)
        node['name'].should == 'andreas'
      end
    end

  end
end