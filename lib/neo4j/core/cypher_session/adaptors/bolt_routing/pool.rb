# frozen_string_literal: true

module Neo4j
  module Core
    module BoltRouting
      class Pool
        def initialize(config: {}, create:, destroy: ->(resource) { true }, validate: ->(resource) { true })
          @acquisition_timeout = config.fetch(:acquisition_timeout, 60)
          @max_size = config.fetch(:max_size, 100)
          @create = create
          @destroy = destroy
          @validate = validate
          @active_resource_counts = Concurrent::Map.new
          @acquire_requests = Concurrent::Map.new
          @pools = Concurrent::Map.new
        end

        def active_resource_count(key)
          @active_resource_counts[key] || 0
        end

        def acquire(key)
          acquire_resource(key).then do |resource|
            if resource.nil?
              @acquire_requests[key] ||= Concurrent::Array.new
              cancellation, token = Concurrent::Cancellation.create
              future = Concurrent::Promises.resolvable_future
              request = PendingRequest.new(future, cancellation)
              @acquire_requests[key] << request

              timeout = Concurrent::Promises.schedule(@acquisition_timeout, request, token) do
                unless token.canceled?
                  @acquire_requests[key].delete(request)

                  request.reject(Neo4j::Core::CypherSession::ConnectionFailedError.new("Connection acquisition timed out after #{ @acquisition_timeout }ms."))
                end
              end

              future | timeout
            else
              resource_acquired!(key)
              resource
            end
          end
        end

        def has(key)
          @pools.has_key?(key)
        end

        def purge(key)
          pool = @pools[key]

          while !pool.size.zero?
            resource = pool.pop
            @destroy.call(resource)
          end

          @pools.delete(key)
        end

        def purge_all
          @pools.each { |key| purge(key) }
        end

        private

        def acquire_resource(key)
          pool = @pools[key]

          if pool.nil?
            pool = Concurrent::Array.new
            @pools[key] = pool
          end

          while !pool.size.zero?
            resource = pool.pop

            if @validate.call(resource)
              Concurrent::Promises.fulfilled_future(resource)
            else
              @destroy.call(resource)
            end
          end

          return Concurrent::Promises.fulfilled_future(nil) if !@max_size.nil? && active_resource_count(key) >= @max_size

          Concurrent::Promises.fulfilled_future(@create.call(key, method(:release)))
        end

        def process_pending_acquire_requests!(key)
          requests = @acquire_requests[key]

          unless requests.nil?
            pending_request = requests.shift

            return @acquire_requests.delete(key) if pending_request.nil?

            acquire_resource(key).rescue(pending_request) do |error, pending_request|
              pending_request.reject(error)
              nil
            end.then(key, pending_request) do |resource, key, pending_request|
              if resource.nil?
                nil
              elsif pending_request.completed?
                release(key, resource)
              else
                resource_acquired!(key)
                pending_request.resolve(resource)
              end
            end
          end
        end

        def release(key, resource)
          pool = @pools[key]

          if pool.nil?
            @destroy.call(resource)
          else
            if @validate.call(resource)
              pool << resource
            else
              @destroy.call(resource)
            end
          end

          resource_released!(key)

          process_pending_acquire_requests!(key)
        end

        def resource_acquired!(key)
          @active_resource_counts[key] ||= 0
          @active_resource_counts[key] += 1
        end

        def resource_released!(key)
          @active_resource_counts[key] -= 1
          @active_resource_counts.delete(key) if @active_resource_counts[key] <= 0
        end

        class PendingRequest
          def initialize(future, cancellation)
            @future = future
            @cancellation = cancellation
            @completed = false
          end

          def completed?
            @completed
          end

          def reject(error)
            return if completed?

            @completed = true
            @cancellation.cancel
            @future.reject(error)
          end

          def resolve(resource)
            return if completed?

            @completed = true
            @cancellation.cancel
            @future.resolve(resource)
          end
        end
      end
    end
  end
end
