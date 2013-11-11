require "rubygems"
require "bundler/setup"
require "rspec"
require "neo4j-core"

require "helpers"

RSpec.configure do |config|
  config.include Helpers

  # Start a clean database beofre all tests run
  config.before :all, api: :rest do
    puts
    puts '#'*26
    puts "Started REST Server"
    puts '='*26
    Helpers::Rest.clean_start
  end

  config.before :all, api: :embedded do
    puts
    puts '#'*26
    puts "Started Embedded Server"
    puts '='*26
    Helpers::Embedded.clean_start
  end

  # Stop the database after you're done
  config.after :all, api: :rest do
    puts
    puts '#'*26
    puts "Stopped REST Server"
    puts '='*26
    Helpers::Rest.stop
  end

  config.after :all, api: :embedded do
    puts
    puts '#'*26
    puts "Stopped Embedded Server"
    puts '='*26
    Helpers::Embedded.stop
  end

  config.exclusion_filter = {
    api: lambda do |type|
      RUBY_PLATFORM != 'java' && type == :embedded
    end
  }
end
