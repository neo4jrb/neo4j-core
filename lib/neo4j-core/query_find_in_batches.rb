module Neo4j::Core
  module QueryFindInBatches

    def find_in_batches(node_var, prop_var, options = {})
      invalid_keys = options.keys.map(&:to_sym) - [:batch_size]
      raise ArgumentError, "Invalid keys: #{invalid_keys.join(', ')}" if not invalid_keys.empty?

      batch_size = options.delete(:batch_size) || 1000

      query = self.reorder(node_var => prop_var).limit(batch_size)

      records = query.to_a

      while records.any?
        records_size = records.size
        primary_key_offset = begin
                               records.last.send(node_var).send(prop_var)
                             rescue NoMethodError
                               begin
                                 records.last.send(node_var)[prop_var.to_sym]
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

