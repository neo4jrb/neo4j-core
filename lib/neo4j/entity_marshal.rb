module Neo4j
  # To support Ruby marshaling
  module EntityMarshal
    def marshal_dump
      marshal_instance_variables.map(&method(:instance_variable_get))
    end

    def marshal_load(array)
      marshal_instance_variables.zip(array).each(&method(:instance_variable_set))
    end

    private

    def marshal_instance_variables
      self.class::MARSHAL_INSTANCE_VARIABLES
    end
  end
end
