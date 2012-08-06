source :gemcutter

gemspec

gem 'neo4j-advanced',  '>= 1.8.M05', '< 1.9', :require => false
gem 'neo4j-enterprise', '>= 1.8.M05', '< 1.9', :require => false

group 'development' do
  gem 'pry'
#  gem 'guard'
#  gem 'rcov', '0.9.11'
#  gem 'ruby_gntp', :require => false # GrowlNotify for Mac
#  gem 'rb-inotify', :require => false
#  gem 'rb-fsevent', :require => false
#  gem 'rb-fchange', :require => false
#  gem "guard-rspec"
  #gem 'ruby-debug-base19' if RUBY_VERSION.include? "1.9"
  #gem 'ruby-debug-base' if RUBY_VERSION.include? "1.8"
  #gem "ruby-debug-ide"
end

group 'test' do
  gem "rake", ">= 0.8.7"
  gem "rspec", "~> 2.8"
  gem "its" # its(:with, :arguments) { should be_possible }
end

