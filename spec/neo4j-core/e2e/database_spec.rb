require 'spec_helper'

include Neo4j
describe Neo4j::Database do

  it "can create a new and find it" do
# Create a new database, which will wrap method with transactions
    # TODO use ImpermanentDatabase
    db = Neo4j::Database.new('hej', auto_commit: true, delete_existing_db: true)

# Create a new label with an index on property name
    red = Label.new(:red)
    red.index(:name)

# how should we specify constraints like unique ?
#   red.index(:name).unique!
#   red.index_unique(:name)
#   red.index(:name, constraints: [:unique])
#   red.index do
#     property :name, contraints: :unique
#   end


# labels argument can be either, string, symbol or Label objects (anything responding to 'to_s')
    node = Node.new({name: 'andreas'}, red, :green)
    puts "Created node #{node[:name]} with labels #{node.labels.map(&:name).join(', ')}"

# Find nodes using the label
    red.find_nodes(:name, "andreas").each do |node|
      # notice that we do not wrap the java object, but instead extend the Java class with ruby methods
      # prints out: FOUND andreas class Java::OrgNeo4jKernelImplCore::NodeProxy with labels red, green
      puts "FOUND #{node[:name]} class #{node.class} with labels #{node.labels.map(&:name).join(', ')}"
    end

  end
end
