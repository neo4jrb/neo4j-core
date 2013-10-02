require 'rubygems'
require "bundler/setup"
require 'rspec'
require 'fileutils'
require 'tmpdir'
#require 'its'
require 'logger'

#require 'neo4j-server'
#require 'neo4j-embedded'
require 'neo4j-core'
#require 'neo4j-wrapper'


Dir["#{File.dirname(__FILE__)}/shared_examples/**/*.rb"].each { |f| require f }


require "#{File.dirname(__FILE__)}/helpers"

RSpec.configure do |c|
  c.include Helpers
end