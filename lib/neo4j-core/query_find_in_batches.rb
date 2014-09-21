module Neo4j::Core
  module QueryFindInBatches

    def find_in_batches(node_var, prop_var, options = {})
      invalid_keys = options.keys.map(&:to_sym) - [:batch_size, :returned_primary_var]
      raise ArgumentError, "Invalid keys: #{invalid_keys.join(', ')}" if not invalid_keys.empty?

      batch_size = options.delete(:batch_size) || 1000
      returned_primary_var = options.delete(:returned_primary_var)

      query = self.reorder(node_var => prop_var).limit(batch_size)

      records = query.to_a

      while records.any?
        records_size = records.size
        primary_key_offset = if returned_primary_var
                            records.last.send(returned_primary_var)
                          else
                            begin
                              records.last.send(node_var).send(prop_var)
                            rescue NoMethodError
                              records.last.send("#{node_var}.#{prop_var}") # In case we're explicitly returning it
                            end
                          end

        yield records

        break if records_size < batch_size

        records = query.where("#{node_var}.#{prop_var} > {primary_key_offset}").params(primary_key_offset: primary_key_offset).to_a
      end
    end

    def find_each(*args)
      find_in_batches(*args) do |batch|
        batch.each { |result| yield result }
      end
    end
  end
end

