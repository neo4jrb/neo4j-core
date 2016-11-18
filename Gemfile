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
  gem 'coveralls', require: false
  gem 'simplecov-html', require: false
  gem 'rspec', '~> 3.0'
  gem 'rspec-its'
  gem 'dotenv'
  gem 'activesupport', RUBY_VERSION.to_f >= 2.2 ? '>= 4.0' : '~> 4'

  gem 'em-http-request', '>= 1.1', require: 'em-http', platforms: :ruby
  gem 'em-synchrony', '>= 1.0.3', require: ['em-synchrony', 'em-synchrony/em-http'], platforms: :ruby
  gem 'excon', '>= 0.27.4'
  gem 'patron', '>= 0.4.2', platforms: :ruby
  gem 'typhoeus', '>= 0.3.3'
end
