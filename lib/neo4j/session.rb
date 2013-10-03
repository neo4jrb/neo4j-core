module Neo4j
  class Session

    @@current_session = nil

    # @abstract
    def close
      self.class.unregister(self)
    end

    # @abstract
    def begin_tx
      raise "not impl."
    end

    class << self
      def current
        @@current_session
      end

      def register(session)
        @@current_session = session unless @@current_session
      end

      def unregister(session)
        @@current_session = nil if @@current_session == session
      end
    end
  end
end