
module Neo4j
  module Core
    class CypherSession
      module Adaptors
        MAP = {}

        class Base
          def connect(*args)
            fail '#connect not implemented!'
          end

          def query(*args)
            queries([cypher_string, parameters])[0]
          end

          def queries(queries_and_parameters)
            fail '#queries not implemented!'
          end
        end
      end
    end
  end
end