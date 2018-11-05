lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'neo4j/core/version'

Gem::Specification.new do |s|
  s.name     = 'neo4j-core'
  s.version  = Neo4j::Core::VERSION
  s.required_ruby_version = '>= 2.1.0'

  s.authors  = 'Andreas Ronge, Chris Grigg, Brian Underwood'
  s.email    = 'andreas.ronge@gmail.com, chris@subvertallmedia.com, brian@brian-underwood.codes'
  s.homepage = 'https://github.com/neo4jrb/neo4j-core'
  s.summary = 'A basic library to work with the graph database Neo4j.'
  s.license = 'MIT'

  s.description = <<-DESCRIPTION
    Neo4j-core provides classes and methods to work with the graph database Neo4j.
DESCRIPTION

  s.require_path = 'lib'
  s.files = Dir.glob('{bin,lib,config}/**/*') + %w[README.md Gemfile neo4j-core.gemspec]
  s.has_rdoc = true
  s.extra_rdoc_files = %w[README.md]
  s.rdoc_options = ['--quiet', '--title', 'Neo4j::Core', '--line-numbers', '--main', 'README.rdoc', '--inline-source']
  s.metadata = {
    'homepage_uri' => 'http://neo4jrb.io/',
    'changelog_uri' => 'https://github.com/neo4jrb/neo4j-core/blob/master/CHANGELOG.md',
    'source_code_uri' => 'https://github.com/neo4jrb/neo4j-core/',
    'bug_tracker_uri' => 'https://github.com/neo4jrb/neo4j-core/issues'
  }

  s.add_dependency('activesupport', '>= 4.0')
  s.add_dependency('concurrent-ruby', '>= 1.1')
  s.add_dependency('concurrent-ruby-edge', '>= 0.4')
  s.add_dependency('faraday', '>= 0.9.0')
  s.add_dependency('faraday_middleware', '>= 0.10.0')
  s.add_dependency('faraday_middleware-multi_json')
  s.add_dependency('httpclient')
  s.add_dependency('json')
  s.add_dependency('multi_json')
  s.add_dependency('net_tcp_client', '>= 2.0.1')
  s.add_dependency('typhoeus', '>= 1.1.2')

  s.add_development_dependency('dryspec')
  s.add_development_dependency('neo4j-rake_tasks', '>= 0.3.0')
  s.add_development_dependency('pry')
  s.add_development_dependency('simplecov')
  s.add_development_dependency('yard')

  if RUBY_PLATFORM =~ /java/
    s.add_development_dependency('neo4j-community', '>= 2.1.1')
    s.add_development_dependency('neo4j-ruby-driver', '!= 1.7.2.beta.1')
    s.add_development_dependency 'ruby-debug'
  end

  s.add_development_dependency('guard')
  s.add_development_dependency('guard-rubocop')
  s.add_development_dependency('rubocop', '~> 0.56.0')
end
