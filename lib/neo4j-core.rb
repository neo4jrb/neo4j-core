require 'ext/kernel'

require 'ostruct'
require 'forwardable'
require 'fileutils'

require 'neo4j-core/version'
require 'neo4j/property_validator'
require 'neo4j/property_container'
require 'neo4j/entity_marshal'
require 'neo4j-core/active_entity'
require 'neo4j-core/helpers'
require 'neo4j-core/query_find_in_batches'
require 'neo4j-core/query'

require 'neo4j/entity_equality'
require 'neo4j/node'
require 'neo4j/label'
require 'neo4j/session'
require 'neo4j/ansi'

require 'neo4j/relationship'
require 'neo4j/transaction'

require 'rake'
load 'neo4j/core/rake_tasks_deprecation.rake'

require 'logger'

module Neo4j
  module Core
    ORIGINAL_FORMATTER = ::Logger::Formatter.new

    def self.logger(stream = STDOUT)
      @logger ||= Logger.new(stream).tap do |logger|
        logger.formatter = method(:formatter)
      end
    end

    def self.formatter(severity, datetime, progname, msg)
      output = ''
      if Thread.current != Thread.main
        output += "#{ANSI::YELLOW}Thread: #{Thread.current.object_id}: #{ANSI::CLEAR}"
      end
      output += msg
      ORIGINAL_FORMATTER.call(severity, datetime, progname, output)
    end
  end
end
