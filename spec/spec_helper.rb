require "rubygems"
require "bundler/setup"
require "rspec"
require "neo4j-core"
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

  config.exclusion_filter = {
    api: lambda do |type|
      RUBY_PLATFORM != 'java' && type == :embedded
    end
  }
end
