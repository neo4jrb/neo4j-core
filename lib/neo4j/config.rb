module Neo4j


  # == Keeps configuration for neo4j
  #
  # The most important configuration is storage_path which is used to
  # locate where the neo4j database is stored on the filesystem.
  # If this directory is empty then a new database will be created, otherwise it will use the
  # database from that directory.
  #
  # == Configurations keys
  #
  #   storage_path   where the database is stored
  #   timestamps     if timestamps should be used when saving the model (Neo4j::Rails::Model)
  #   lucene         lucene configuration for fulltext and exact indices
  #   enable_rules   if false the _all relationship to all instances will not be created and custom rules will not be available. (Neo4j::NodeMixin and Neo4j::Rails::Model)
  #   identity_map   default false, See Neo4j::IdentityMap  (Neo4j::NodeMixin and Neo4j::Rails::Model)
  #
  class Config

    class << self

      # @return [Fixnum] The location of the default configuration file.
      def default_file
        @default_file ||= File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "neo4j", "config.yml"))
      end

      # Sets the location of the configuration YAML file and old deletes configurations.
      #
      # @param [String] file_path represent the path to the file.
      def default_file=(file_path)
        @configuration = nil
        @defaults = nil
        @default_file = File.expand_path(file_path)
      end

      # @return [Hash] the default file loaded by yaml
      def defaults
        require 'yaml'
        @defaults ||= YAML.load_file(default_file)
      end

      # @return [String] the expanded path of the Config[:storage_path] property
      def storage_path
        File.expand_path(self[:storage_path])
      end

      # Yields the configuration
      #
      # @example
      #   Neo4j::Config.use do |config|
      #     config[:storage_path] = '/var/neo4j'
      #   end
      #
      # @return nil
      # @yield config
      # @yieldparam [Neo4j::Config] config - this configuration class
      def use
        @configuration ||= {}
        yield @configuration
        nil
      end


      # Sets the value of a config entry.
      #
      # @param [Symbol] key the key to set the parameter for
      # @param val the value of the parameter.
      def []=(key, val)
        (@configuration ||= setup)[key.to_s] = val
      end


      # @param [Symbol] key The key of the config entry value we want
      # @return the the value of a config entry
      def [](key)
        (@configuration ||= setup)[key.to_s]
      end


      # Remove the value of a config entry.
      #
      # @param [Symbol] key the key of the configuration entry to delete
      # @return The value of the removed entry.
      def delete(key)
        @configuration.delete(key)
      end


      # Remove all configuration. This can be useful for testing purpose.
      #
      # @return nil
      def delete_all
        @configuration = nil
      end


      # @return [Hash] The config as a hash.
      def to_hash
        @configuration ||= setup
      end

      # @return [String] The config as a YAML
      def to_yaml
        @configuration.to_yaml
      end

      # Converts the defaults hash to a Java HashMap used by the Neo4j API.
      # @return a Java HashMap used by the Java Neo4j API as configuration for the GraphDatabase
      def to_java_map
        map = java.util.HashMap.new
        to_hash.each_pair do |k, v|
          case v
            when TrueClass
              map[k.to_s] = "YES"
            when FalseClass
              map[k.to_s] = "NO"
            when String, Fixnum, Float
              map[k.to_s] = v.to_s
            # skip list and hash values - not accepted by the Java Neo4j API
          end
        end
        map
      end

      # @return The a new configuration using default values as a hash.
      def setup()
        @configuration = {}
        @configuration.merge!(defaults)
        @configuration
      end

    end
  end

end