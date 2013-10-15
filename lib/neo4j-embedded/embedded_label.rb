module Neo4j::Embedded
  class EmbeddedLabel
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

    def find_nodes(key=nil, value=nil)
       begin
        iterator = _find_nodes(key,value)
        iterator.to_a
      ensure
        iterator && iterator.close
      end
    end
    tx_methods :find_nodes

    def _find_nodes(key=nil, value=nil)
      if (key)
        @session.graph_db.find_nodes_by_label_and_property(as_java, key, value).iterator
      else
        ggo = Java::OrgNeo4jTooling::GlobalGraphOperations.at(@session.graph_db)
        ggo.getAllNodesWithLabel(as_java).iterator
      end

    end

    def as_java
      self.class.as_java(@name.to_s)
    end

    def create_index(*properties)
        index_creator = @session.graph_db.schema.index_for(as_java)
      # we can also use the PropertyConstraintCreator here
      properties.inject(index_creator) {|creator, key| creator.on(key.to_s)}.create
    end
    tx_methods :create_index

    def indexes()
      @session.graph_db.schema.indexes(as_java).map do |index_def|
        index_def.property_keys.map{|x| x.to_sym}
      end
    end
    tx_methods :indexes

    def drop_index(*properties)
      @session.graph_db.schema.indexes(as_java).each do |index_def|
        # at least one match, TODO
        keys = index_def.property_keys.map{|x| x.to_sym}
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

