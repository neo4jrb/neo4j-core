module Neo4jSpecHelpers
  class << self
    attr_accessor :expect_queries_count
  end

  self.expect_queries_count = 0

  Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query do |_message|
    self.expect_queries_count += 1
  end

  def expect_queries(count)
    start_count = Neo4jSpecHelpers.expect_queries_count
    yield
    expect(Neo4jSpecHelpers.expect_queries_count - start_count).to eq(count)
  end

  def delete_schema(session = nil)
    Neo4j::Core::Label.drop_uniqueness_constraints_for(session || current_session)
    Neo4j::Core::Label.drop_indexes_for(session || current_session)
  end

  def create_constraint(session, label_name, property, options = {})
    label_object = Neo4j::Core::Label.new(label_name, session)
    label_object.create_constraint(property, options)
  end

  def create_index(session, label_name, property, options = {})
    label_object = Neo4j::Core::Label.new(label_name, session)
    label_object.create_index(property, options)
  end
end
