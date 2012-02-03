class MockDb
  attr_accessor :event_handler

  def register_transaction_event_handler(event_handler)
    @event_handler = event_handler
  end

  def unregister_transaction_event_handler(event_handler)
    @event_handler = nil
  end

  def index

  end

  def java_class
    Java::OrgNeo4jKernel::EmbeddedGraphDatabase
  end

  def shutdown

  end
end