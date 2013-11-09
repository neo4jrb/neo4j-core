module Neo4j::Wrapper
  module NodeMixin
    include Neo4j::Wrapper::Initialize
    include Neo4j::Wrapper::Delegates
    include Neo4j::EntityEquality

    # @private
    def self.included(klass)
      klass.extend  Neo4j::Wrapper::Initialize::ClassMethods
      klass.extend Neo4j::Wrapper::Labels::ClassMethods
      klass.send(:include, Neo4j::Wrapper::Labels)
    end
  end

end
