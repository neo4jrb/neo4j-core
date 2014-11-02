lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'neo4j-core/version'

Gem::Specification.new do |s|
  s.name     = "neo4j-core"
  s.version  = Neo4j::Core::VERSION
  s.required_ruby_version = ">= 1.8.7"

  s.authors  = "Andreas Ronge"
  s.email    = 'andreas.ronge@gmail.com'
  s.homepage = "https://github.com/neo4jrb/neo4j-core"
  s.rubyforge_project = 'neo4j-core'
  s.summary = "A graph database for Ruby"
  s.license = 'MIT'

  s.description = <<-EOF
Neo4j-core provides classes and methods to work with the graph database Neo4j.
  EOF

  s.require_path = 'lib'
  s.files = Dir.glob("{bin,lib,config}/**/*") + %w(README.md Gemfile neo4j-core.gemspec)
  s.has_rdoc = true
  s.extra_rdoc_files = %w( README.md )
  s.rdoc_options = ["--quiet", "--title", "Neo4j::Core", "--line-numbers", "--main", "README.rdoc", "--inline-source"]

  # Not released yet
  s.add_dependency("httparty")
  s.add_dependency("faraday", '~> 0.9.0')
  s.add_dependency('net-http-persistent')
  s.add_dependency('httpclient')
  s.add_dependency('faraday_middleware', '~> 0.9.1')
  s.add_dependency("json")
  s.add_dependency("os")  # for Rake task
  s.add_dependency("zip") # for Rake task
  s.add_dependency("activesupport") # For ActiveSupport::Notifications

  if RUBY_PLATFORM == 'java'
    s.add_dependency("neo4j-community", '~> 2.1.1')
    s.add_development_dependency 'ruby-debug'
  end
end
