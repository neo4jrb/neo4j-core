
module Neo4j
  module Core
    class CypherSession
      module Adaptors
        MAP = {}

        class Base
          def connect(*_args)
            fail '#connect not implemented!'
          end

          def query(*_args)
            queries([cypher_string, parameters])[0]
          end

          def queries(_queries_and_parameters)
            fail '#queries not implemented!'
          end
        end
      end
    end
  end
end
