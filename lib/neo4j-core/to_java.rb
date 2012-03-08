module Neo4j
  module Core
    # A Utility class for translating Ruby object to Neo4j Java types
    module ToJava
      def type_to_java(type)
        Java::OrgNeo4jGraphdb::DynamicRelationshipType.withName(type.to_s)
      end

      module_function :type_to_java

      def dir_from_java(dir)
        case dir
          when Java::OrgNeo4jGraphdb::Direction::OUTGOING then
            :outgoing
          when Java::OrgNeo4jGraphdb::Direction::BOTH then
            :both
          when Java::OrgNeo4jGraphdb::Direction::INCOMING then
            :incoming
          else
            raise "unknown direction '#{dir} / #{dir.class}'"
        end
      end

      module_function :dir_from_java

      def dir_to_java(dir)
        case dir
          when :outgoing then
            Java::OrgNeo4jGraphdb::Direction::OUTGOING
          when :both then
            Java::OrgNeo4jGraphdb::Direction::BOTH
          when :incoming then
            Java::OrgNeo4jGraphdb::Direction::INCOMING
          else
            raise "unknown direction '#{dir}', expects :outgoing, :incoming or :both"
        end
      end

      module_function :dir_to_java

    end
  end
end