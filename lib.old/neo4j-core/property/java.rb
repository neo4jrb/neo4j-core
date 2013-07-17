module Neo4j
  module Core
    module Property
      # This module is only used for documentation purpose
      # It simplify declares the java methods which are available Java org.neo4j.graphdb.PropertyContainer
      # @see http://api.neo4j.org/1.6.1/org/neo4j/graphdb/PropertyContainer.html
      module Java


        # Get the GraphDatabaseService that this Node or Relationship belongs to.
        # @return [Java::Neo4jGraphdbGraphDatabaseService]
        def graph_database
        end

        # Returns the property value associated with the given key, or a default value.
        # The value is of one of the valid property types, i.e. a Java primitive, a String or an array of any of the valid types.
        # If there's no property associated with key an unchecked exception is raised.
        # The idiomatic way to avoid an exception for an unknown key and instead get null back is to use a default value: Object valueOrNull = nodeOrRel.getProperty( key, null )
        # @param [String] key the property key
        # @param [String] default_value the default value that will be returned if no property value was associated with the given key
        # @return [String,Fixnum,Boolean,Float,Array] ]the property value associated with the given key.
        # @raise an exception if not given a default value and there is no property for the given key
        # @see Neo4j::Core:Property#[]
        def get_property(key, default_value = nil)
        end

        # @return all existing property keys, or an empty iterable if this property container has no properties.
        def property_keys
        end


        # Removes the property associated with the given key and returns the old value.
        # @param [String] key the name of the property
        # @return [String,Fixnum,Boolean,Float,Array, nil] The old value or <tt>nil</tt> if there's no property associated with the key.
        def remove_property(key)
        end

        # Sets the property value for the given key to value.
        # The property value must be one of the valid property types, i.e:
        # * boolean or boolean[]
        # * byte or byte[]
        # * short or short[]
        # * int or int[]
        # * long or long[]
        # * float or float[]
        # * double or double[]
        # * char or char[]
        # * java.lang.String or String[]
        # Notice that JRuby does map Ruby primitive object (e.g. Fixnum) to java primitives automatically.
        # Also, nil is not an accepted property value.
        # @param [String] key the property key
        # @param [String,Fixnum,Boolean,Float,Array] value
        # @see Neo4j::Core::Property#[]=
        def set_property(key, value)
        end
      end
    end
  end
end