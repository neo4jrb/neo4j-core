module Neo4j
  class Label
    extend Neo4j::Core::TxMethods
    attr_reader :name
    JAVA_CLASS = Java::OrgNeo4jGraphdb::DynamicLabel

    def initialize(name)
      @name = name.to_s
    end

    def to_s
      @name
    end

    def find_nodes(key, value, db = Database.instance)
      Neo4j::Core::ResourceIterator.new db.find_nodes_by_label_and_property(as_java, key, value)
    end

    def as_java
      self.class.as_java(@name)
    end

    def index(*properties)
      db = properties.last.kind_of?(Database) ? properties.pop : Database.instance
      index_creator = db.schema.index_for(as_java)
      # we can also use the PropertyConstraintCreator here
      properties.inject(index_creator) {|creator, key| creator.on(key.to_s)}.create
    end
    tx_methods :index

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

