lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'neo4j-core/version'

Gem::Specification.new do |s|
  s.name     = 'neo4j-core'
  s.version  = Neo4j::Core::VERSION
  s.required_ruby_version = '>= 1.9.3'

  s.authors  = 'Andreas Ronge, Chris Grigg, Brian Underwood'
  s.email    = 'andreas.ronge@gmail.com, chris@subvertallmedia.com, brian@brian-underwood.codes'
  s.homepage = 'https://github.com/neo4jrb/neo4j-core'
  s.summary = 'A basic library to work with the graph database Neo4j.'
  s.license = 'MIT'

  s.description = <<-EOF
Neo4j-core provides classes and methods to work with the graph database Neo4j.
  EOF

  s.require_path = 'lib'
  s.files = Dir.glob('{bin,lib,config}/**/*') + %w(README.md Gemfile neo4j-core.gemspec)
  s.has_rdoc = true
  s.extra_rdoc_files = %w( README.md )
  s.rdoc_options = ['--quiet', '--title', 'Neo4j::Core', '--line-numbers', '--main', 'README.rdoc', '--inline-source']

  s.add_dependency('httparty')
  s.add_dependency('faraday', '~> 0.9.0')
  s.add_dependency('net-http-persistent')
  s.add_dependency('httpclient')
  s.add_dependency('faraday_middleware', '~> 0.9.1')
  s.add_dependency('json')
  s.add_dependency('os')  # for Rake task
  s.add_dependency('zip') # for Rake task
  s.add_dependency('activesupport') # For ActiveSupport::Notifications
  s.add_dependency('multi_json')
  s.add_dependency('faraday_middleware-multi_json')

  s.add_development_dependency('pry')
  s.add_development_dependency('yard')
  s.add_development_dependency('simplecov')
  s.add_development_dependency('guard')
  s.add_development_dependency('guard-rubocop')
  s.add_development_dependency('rubocop', '~> 0.29.1')

  if RUBY_PLATFORM == 'java'
    s.add_dependency('neo4j-community', '>= 2.1.1')
    s.add_development_dependency 'ruby-debug'
  end
end
