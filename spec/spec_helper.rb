require "rubygems"
require "bundler/setup"
require "rspec"
require "neo4j-core"
require "byebug"

require "helpers"

RSpec.configure do |config|
  config.include Helpers

  # Start a clean database beofre all tests run
  config.before :all, api: :rest do
    Helpers::Rest.clean_start
  end

  config.before :all, api: :embedded do
    Helpers::Embedded.clean_start
  end

  # Stop the database after you're done
  config.after :all, api: :rest do
    Helpers::Rest.stop
  end

  config.after :all, api: :embedded do
    Helpers::Embedded.stop
  end

  config.exclusion_filter = {
    api: lambda do |type|
      RUBY_PLATFORM != 'java' && type == :embedded
    end
  }
end
