require "rubygems"
require "bundler/setup"
require "rspec"
require "neo4j-core"

require "helpers"

RSpec.configure do |config|
  config.include Helpers

  # Start the database beofre all tests run
  config.before :all, api: :rest do
    Helpers::Rest.clean
    Helpers::Rest.run
  end

  config.before :all, api: :embedded do
    Helpers::Embedded.clean
    Helpers::Embedded.run
  end

  config.exclusion_filter = {
    api: lambda do |type|
      RUBY_PLATFORM != 'java' && type == :embedded
    end
  }
end
