# frozen_string_literal: true

module Neo4j
  module Core
    module BoltRouting
      class Pool
        def initialize(config: {}, create:)
          @acquisition_timeout = config.fetch(:acquisition_timeout, 60)
          @create = create
          @destroy = destroy
          @max_size = config.fetch(:max_size, 100)
          @pools = {}
          @validate = validate
        end

        def active_resource_count(key)
          pool = @pools[key]

          return 0 if pool.nil?

          pool.size - pool.available
        end

        def acquire(key)
          acquire_resource(key) do |conn|
            yield conn
          end
        end

        def has(key)
          !@pools[key].nil?
        end

        def purge(key)
          pool = @pools[key]
          pool.shutdown { |conn| conn.close }
          @pools.delete(key)
        end

        def purge_all
          @pools.each { |key, _value| purge(key) }
        end

        private

        def acquire_resource(key)
          pool = @pools[key]
          if pool.nil?
            pool = ConnectionPool.new(size: @max_size, timeout: @acquisition_timeout) do
              @create.call(key)
            end
            @pools[key] = pool
          end

          pool.with do |conn|
            yield conn
          end
        end
      end
    end
  end
end
