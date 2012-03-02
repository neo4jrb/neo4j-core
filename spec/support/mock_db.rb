class MockDb
  attr_accessor :event_handler, :index

  def initialize(*)
    @index = Object.new
  end

  def register_transaction_event_handler(event_handler)
    @event_handler = event_handler
  end

  def unregister_transaction_event_handler(event_handler)
    @event_handler = nil
  end

  def java_class
    Java::OrgNeo4jKernel::EmbeddedGraphDatabase
  end

  def shutdown

  end
end