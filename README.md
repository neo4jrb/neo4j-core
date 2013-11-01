# Neo4j-core


## Installation


### Usage from Neo4j Server

You need to install the Neo4j server. This can be done by included Rake file.

Example

```
rake neo4j:install[community-2.0.0,M05]
rake neo4j:start
```

### Usage from Neo4j Embedded

The Gemfile contains references to Neo4j Java libraries. Nothing is needed to be installed.


## Version 3.0 Specification

The neo4j-core version 3.0 uses the java Jar and/or the Neo4j Server version 2.0.0-M4+ . This mean that it should work on
Ruby implementation and not just JRuby !

It uses the new label feature in order to do mappings between `Neo4j::Node` (java objects) and your own ruby classes.

The code base for the 3.0 should be smaller and simpler to maintain because there is less work to be done in the
Ruby layer but also by removing features that are too complex or not that useful.

The neo4j-wrapper source code is included in this git repo until the refactoring has stabilized.
The old source code for neo4j-core is also included (lib.old). The old source code might later on be copied into the
 3.0 source code (the lib folder).

The neo4j-core gem will work for both the embedded Neo4j API and the server api.
That means that neo4j.rb will work on any Ruby implementation and not just JRuby. This is under investigation !
It's possible that some features for the Neo4j.rb 2.0 will not be available in the 3.0 version since it has to work
 with both the Neo4j server and Neo4j embedded APIs.

Since neo4j-core provides one unified API to both the server end embedded neo4j database the neo4j-wrapper and neo4j
gems will also work with server and embedded neo4j databases.

New features:

* neo4j-core provides the same API to both the Embedded database and the Neo4j Server
* auto commit is each operation is now default (neo4j-core)

Removed features:

* auto start of the database (neo4j-core)
* wrapping of Neo4j::Relationship java objects but there will be a work around (neo4j-wrapper)
* traversals (the outgoing/incoming/both methods) moves to a new gem, neo4j-traversal.
* rules will not be supported
* versioning will not be supported, will Neo4j support it ?
* multitenancy will not be supported, will Neo4j support it ?

Changes:

* `Neo4j::Node.create` now creates a node instead of `Neo4j::Node.new`
* `Neo4j::Node#rels` different arguments, see below
* Many Neo4j Java methods requires you to close an ResourceIterable as well as be in an transaction (even for read operations)
In neo4j-core there are two version of these methods, one that create transaction and close the iterable for you and one raw
where you have to do it yourself (which may give you be better performance).

Future (when Neo4j 2.1 is released)
* Support for fulltext search
* Compound keys in index

### Status 2013-10-04

* Impl. CRUD operations on nodes/relationships
* Impl. navigation of relationships
* Indexing via label works
* Using 2.0.0-M6

For detail status what works, see the RSpecs.


## Neo4j-core API

Example of index using labels and the auto commit.


### Creating a database session

There are currently two available types of session, one for connecting to a neo4j server
and one for connecting to the embedded Neo4j database (which requires JRuby).

Using the Neo4j Server: `:cypher_server_db`

```ruby
  # Using Neo4j Server Cypher Database
  session = Neo4j::Session.open(:server_db, "http://localhost:7474")
```

Using the Neo4j Embedded Database, `:local_embedded_db`

```ruby
  # Using Neo4j Embedded Database
  session = Neo4j::Session.open(:embedded_db, '/folder/db', auto_commit: true)
  session.start
```

When a session has been created it will be stored in the `Neo4j::Session` object.
Example, get the default session

```ruby
session = Neo4j::Session.current
```

The default session is used by all operation unless specified as the last argument.
For example create a node with a different session:

```ruby
my_session = Neo4j::Session.open(:server_db, "http://localhost:7474")
Neo4j::Node.create(name: 'kalle', my_session)
```


### Label and Index Support

Create a node with an label `person` and one property
```ruby
Neo4j::Node.create({name: 'kalle'}, :person)
```

Add index on a label

```ruby
  person = Label.create(:person)
  person.create_index(:name) # compound keys will be supported in Neo4j 2.1

  # drop index
  person.drop_index(:name)
```

```ruby
  # which indexes do we have and on which properties,
  red.indexes.each {|i| puts "Index #{i.label} properties: #{i.properties}"}

  # drop index, we assume it's the first one we want
  red.indexes.first.drop(:name)

  # which indices exist ?
  # (compound keys will be supported in Neo4j 2.1 (?))
  red.indexes # => {:property_keys => [[:age]]}
```

### Creating Nodes

```ruby
  # notice, label argument can be both Label objects or string/symbols.
  node = Node.create({name: 'andreas'}, red, :green)
  puts "Created node #{node[:name]} with labels #{node.labels.map(&:name).join(', ')}"
```

Notice, nodes will be indexed based on which labels they have.


### Finding Nodes

```ruby
  # Find nodes using an index, returns an Enumerable
  Neo4j::Label.find_nodes(:red, :name, "andreas")

  # Find all nodes for this label, returns an Enumerable
  Neo4j::Label.find_all_nodes(:red)

  # which labels does a node have ?
  node.labels # [:red]
```

All method prefixed with `_` gives direct access to the java layer/rest layer.
Notice, the database starts with auto commit by default.

Example, Finding with order by on label :person

```ruby
  Neo4j::Label.query(:person, order: [:name, {age: :asc}])
```

### Identity

NOT WORKING YET, TODO.
By default the identity for a node is the same as the native Neo4j id.
You can specify your own identity of nodes.

```ruby
session = Neo4j::CypherDatabase.connect('URL')
session.config.node_identity = '_my_id'
```

### Transactions

By default each Neo4j operation is wrapped in an transaction.
If you want to execute several operation in one operation you can use the `Neo4j::Transaction` class, example:

```ruby
Neo4j::Transaction.run do
  n = Neo4j::Node.create(name: 'kalle')
  n[:age] = 42
end
```

### Relationship

How to create a relationship between node n1 and node n2 with one property

```ruby
n1 = Neo4j::Node.create
n2 = Neo4j::Node.create
rel = n1.create_rel(:knows, n2, since: 1994)
```

Finding relationships

```ruby
# any type any direction any label
n1.rels

# Outgoing of one type:
n1.rels(dir: :outgoing, type: :know).to_a

# same but expects only one relationship
n1.rel(dir: :outgoing, type: :best_friend)

# several types
n1.rels(types: [:knows, :friend])

# label
n1.rels(label: :rich)

# matching several labels
n1.rels(labels: [:rich, :poor])

# outgoing between two nodes
n1.rels(dir: :outgoing, between: n2)
```

Returns nodes instead of relationships

```ruby
# same parameters as rels method
n1.nodes(dir: outgoing)
n1.node(dir: outgoing)
```


Delete relationship

```ruby
rel = n1.rel(:outgoing, :know) # expects only one relationship
rel.del
```

## Implementation:

No state is cached in the neo4j-core (e.g. neo4j properties).

The public `Neo4j::Node` classes is abstract and provides a common API/docs for both the embedded and
  neo4j server.

The Neo4j::Embedded and Neo4j::Server modules contains drivers for classes like the `Neo4j::Node`.
This is implemented something like this:

```ruby
  class Neo4j::Node
    # YARD docs
    def [](key)
      # abstract method - impl using either HTTP or Java API
      get_property(key,session=Neo4j::Session.current)
    end


    def self.create(props, session=Neo4j::Session.current)
     session.create_node(props)
    end
  end
```

Both implementation use the same E2E specs.

## Neo4j-wrapper API

Example of mapping a Neo4j::Node java object to your own class.

```ruby
  # will use Neo4j label 'Person'
  class Person
    include Neo4j::NodeMixin
  end

  # find all person instances
  Person.find_all
```

Using an index

```ruby
  # will use Neo4j label 'Person'
  class Person
    include Neo4j::NodeMixin
    index :name
  end

  # find all person instances with key value = name, andreas
  andreas = Person.create(:name => 'andreas')
  Person.find(:name, 'andreas')  # will include andreas
```


Example of mapping the Baaz ruby class to Neo4j labels 'Foo', 'Bar' and 'Baaz'

```ruby
  module Foo
    def self.mapped_label_name
       "Foo" # specify the label for this module
    end
  end

  module Bar
    extend Neo4j::Wrapper::LabelIndex # to make it possible to search using this module (?)
    index :stuff # (?)
  end

  class Baaz
    include Foo
    include Bar
    include Neo4j::NodeMixin
  end

  Bar.find_nodes(...) # can find Baaz object but also other objects including the Bar mixin.
```

Example of inheritance.

```ruby
  # will only use the Vehicle label
  class Vehicle
    include Neo4j::NodeMixin
  end

  # will use both Car and Vehicle labels
  class Car < Vehicle
  end
```

## Testing

The testing will be using much more mocking.

* The `unit` rspec folder only contains testing for one Ruby module. All other modules should be mocked.
* The `integration` rspec folder contains testing for two or more modules but mocks the neo4j database access.
* The `e2e` rspec folder for use the real database (or Neo4j's ImpermanentDatabase (todo))
* The `shared_examples` common specs for different types of databases


## The public API

* `Neo4j::Node` The Java Neo4j Node

* {Neo4j::Relationship} The Java Relationship

* {Neo4j::Database} The (default) Database

* {Neo4j::Embedded::Database} - good name ?

* {Neo4j::Server::RestDatabase}

* {Neo4j::Server::CypherDatabase}

* {Neo4j::Cypher} Cypher Query DSL, see {Neo4j Wiki}[https://github.com/andreasronge/neo4j/wiki/Neo4j%3A%3ACore-Cypher]

* {Neo4j::Algo} Included algorithms, like shortest path

## License
* Neo4j.rb - MIT, see the LICENSE file http://github.com/andreasronge/neo4j-core/tree/master/LICENSE.
* Lucene -  Apache, see http://lucene.apache.org/java/docs/features.html
* \Neo4j - Dual free software/commercial license, see http://neo4j.org/

Notice there are different license for the neo4j-community, neo4j-advanced and neo4j-enterprise jar gems.
Only the neo4j-community gem is by default required.
