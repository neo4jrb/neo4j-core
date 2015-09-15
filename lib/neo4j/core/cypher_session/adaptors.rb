
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
            fail '#query not implemented!'
          end
        end
      end
    end
  end
end