source 'https://rubygems.org'

gemspec

# gem 'neo4j-advanced',   '>= 1.8.1', '< 2.0', :require => false
# gem 'neo4j-enterprise', '>= 1.8.1', '< 2.0', :require => false

group 'development' do
  gem 'guard-rspec', require: false if RUBY_PLATFORM != 'java'
  gem 'overcommit'
end

group 'test' do
  gem 'coveralls', require: false
  gem 'simplecov-html', require: false
  gem 'rspec', '~> 3.0'
  gem 'rspec-its'
  gem 'dotenv'
  gem 'activesupport', '~> 4.0'
end
