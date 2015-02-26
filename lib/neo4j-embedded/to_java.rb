module Neo4j
  module Embedded
    # A Utility class for translating Ruby object to Neo4j Java types
    # @private
    module ToJava
      def type_to_java(type)
        type && Java::OrgNeo4jGraphdb::DynamicRelationshipType.withName(type.to_s)
      end

      module_function :type_to_java

      def types_to_java(types)
        types.inject([]) { |result, type| result << type_to_java(type) }.to_java(Java::OrgNeo4jGraphdb::RelationshipType)
      end

      module_function :types_to_java


      def dir_from_java(dir)
        case dir
        when Java::OrgNeo4jGraphdb::Direction::OUTGOING then :outgoing
        when Java::OrgNeo4jGraphdb::Direction::BOTH then :both
        when Java::OrgNeo4jGraphdb::Direction::INCOMING then :incoming
        else
          fail "unknown direction '#{dir} / #{dir.class}'"
        end
      end

      module_function :dir_from_java

      def dir_to_java(dir)
        case dir
        when :outgoing then Java::OrgNeo4jGraphdb::Direction::OUTGOING
        when :both then Java::OrgNeo4jGraphdb::Direction::BOTH
        when :incoming then Java::OrgNeo4jGraphdb::Direction::INCOMING
        else
          fail "unknown direction '#{dir}', expects argument: outgoing, :incoming or :both"
        end
      end

      module_function :dir_to_java
    end
  end
end
