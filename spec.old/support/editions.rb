#require 'spec/support/rspec'

module Neo4jSpecEdition
  def self.current
    edition = ENV['EDITION'] || ENV['ED']
    (edition && !edition.empty?) ? edition.downcase.to_sym : nil
  end
end

RSpec.configure do |c|
  edition =  Neo4jSpecEdition.current

  if edition
    require "neo4j-#{edition}"
    puts "RUN #{edition}"
    c.filter = { :edition => edition.to_sym }
  else
    # If no edition provided, we need to exclude specs tagged with :edition
    c.exclusion_filter = {
      :edition => lambda {|ed| [:enterprise, :advanced].include?(ed) }
    }
  end
end
