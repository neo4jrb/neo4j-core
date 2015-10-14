module Neo4j
  module Embedded
    class EmbeddedLabel < Neo4j::Label
      extend Neo4j::Core::TxMethods
      attr_reader :name
      JAVA_CLASS = Java::OrgNeo4jGraphdb::DynamicLabel

      def initialize(session, name)
        @name = name.to_sym
        @session = session
      end

      def to_s
        @name
      end

      def find_nodes(key = nil, value = nil)
        iterator = if key
                     @session.graph_db.find_nodes_by_label_and_property(as_java, key, value).iterator
                   else
                     ggo = Java::OrgNeo4jTooling::GlobalGraphOperations.at(@session.graph_db)
                     ggo.getAllNodesWithLabel(as_java).iterator
                   end

        iterator.to_a.map(&:wrapper)
      ensure
        iterator && iterator.close
      end
      tx_methods :find_nodes

      def as_java
        self.class.as_java(@name.to_s)
      end

      def create_index(property, options = {}, session = Neo4j::Session.current)
        validate_index_options!(options)
        index_creator = session.graph_db.schema.index_for(as_java)
        # we can also use the PropertyConstraintCreator here
        properties = property.is_a?(Array) ? property : [property]
        properties.inject(index_creator) { |creator, key| creator.on(key.to_s) }.create
      end
      tx_methods :create_index

      def indexes
        {
          property_keys: @session.graph_db.schema.indexes(as_java).map do |index_def|
            index_def.property_keys.map(&:to_sym)
          end
        }
      end
      tx_methods :indexes

      def uniqueness_constraints
        definitions = @session.graph_db.schema.constraints(as_java).select do |index_def|
          index_def.is_a?(Java::OrgNeo4jKernelImplCoreapiSchema::PropertyUniqueConstraintDefinition)
        end
        {
          property_keys: definitions.map { |index_def| index_def.property_keys.map(&:to_sym) }
        }
      end
      tx_methods :uniqueness_constraints


      def drop_index(property, options = {}, session = Neo4j::Session.current)
        validate_index_options!(options)
        properties = property.is_a?(Array) ? property : [property]
        session.graph_db.schema.indexes(as_java).each do |index_def|
          # at least one match, TODO
          keys = index_def.property_keys.map(&:to_sym)
          index_def.drop if (properties - keys).count < properties.count
        end
      end
      tx_methods :drop_index

      class << self
        def as_java(labels)
          if labels.is_a?(Array)
            return nil if labels.empty?

            labels.inject([]) { |result, label| result << JAVA_CLASS.label(label.to_s) }.to_java(JAVA_CLASS)
          else
            JAVA_CLASS.label(labels.to_s)
          end
        end
      end
    end
  end
end
