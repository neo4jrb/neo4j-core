module Neo4j
  class Session

    @@current_session = nil

    # @abstract
    def close
      self.class.unregister(self)
    end

    # Only for embedded database
    # @abstract
    def start
      raise "not impl."
    end

    # Only for embedded database
    # @abstract
    def shutdown
      raise "not impl."
    end

    # Only for embedded database
    # @abstract
    def running
      raise "not impl."
    end

    def auto_commit?
      true # TODO
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