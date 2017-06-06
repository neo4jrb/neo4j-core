source 'https://rubygems.org'

gemspec

# gem 'neo4j-advanced',   '>= 1.8.1', '< 2.0', :require => false
# gem 'neo4j-enterprise', '>= 1.8.1', '< 2.0', :require => false

gem 'tins', '< 1.7' if RUBY_VERSION.to_f < 2.0

group 'development' do
  gem 'guard-rspec', require: false if RUBY_PLATFORM != 'java'
  if RUBY_VERSION.to_f < 2.0
    gem 'overcommit', '< 0.35.0'
    gem 'term-ansicolor', '< 1.4'
  else
    gem 'overcommit'
  end
end

group 'test' do
  gem 'activesupport', '~> 4.0'
  gem 'coveralls', require: false
  gem 'dotenv'
  gem 'rspec', '~> 3.0'
  gem 'rspec-its'
  gem 'simplecov-html', require: false
end
