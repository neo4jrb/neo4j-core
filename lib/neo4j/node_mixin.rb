module Neo4j
  module NodeMixin
    include Neo4j::Wrapper::Initialize

    def self.included(klass)
      klass.extend Neo4j::Wrapper::ClassMethods
      klass.extend Neo4j::Wrapper::Labels::ClassMethods
      klass.extend Neo4j::Labeling
    end
  end
end