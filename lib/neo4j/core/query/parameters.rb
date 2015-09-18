module Neo4j
  module Core
    class Query
      class Parameters
        def initialize(hash = nil)
          @parameters = (hash || {})
        end

        def to_hash
          @parameters
        end

        def copy
          self.class.new(@parameters.dup)
        end

        def add_param(key, value)
          free_param_key(key).tap do |k|
            @parameters[k.freeze] = value
          end
        end

        def remove_param(key)
          @parameters.delete(key.to_sym)
        end

        def add_params(params)
          params.map do |key, value|
            add_param(key, value)
          end
        end

        private

        def free_param_key(key)
          k = key.to_sym

          return k if !@parameters.key?(k)

          i = 2
          i += 1 while @parameters.key?("#{key}#{i}".to_sym)

          "#{key}#{i}".to_sym
        end
      end
    end
  end
end
