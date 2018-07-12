# Neo4j-core

[![Actively Maintained](https://img.shields.io/badge/Maintenance%20Level-Actively%20Maintained-green.svg)](https://gist.github.com/cheerfulstoic/d107229326a01ff0f333a1d3476e068d)
[![Code Climate](https://codeclimate.com/github/neo4jrb/neo4j-core.svg)](https://codeclimate.com/github/neo4jrb/neo4j-core)
[![Build Status](https://travis-ci.org/neo4jrb/neo4j-core.svg)](https://travis-ci.org/neo4jrb/neo4j-core)
[![Coverage Status](https://coveralls.io/repos/neo4jrb/neo4j-core/badge.svg?branch=master)](https://coveralls.io/r/neo4jrb/neo4j-core?branch=master)
[![PullReview stats](https://www.pullreview.com/github/neo4jrb/neo4j-core/badges/master.svg?)](https://www.pullreview.com/github/neo4jrb/neo4j-core/reviews/master)

A simple Ruby wrapper around the Neo4j graph database that works with the server and embedded Neo4j API. This gem can be used both from JRuby and normal MRI.
It can be used standalone without the neo4j gem.

## Basic usage

### Executing Cypher queries

To make a basic connection to Neo4j to execute Cypher queries, first choose an adaptor.  Adaptors for HTTP, Bolt, and Embedded mode (jRuby only) are available.  You can create an adaptor like:

    require 'neo4j/core/cypher_session/adaptors/http'
    http_adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new('http://neo4j:pass@localhost:7474', options)

    # or

    require 'neo4j/core/cypher_session/adaptors/bolt'
    bolt_adaptor = Neo4j::Core::CypherSession::Adaptors::Bolt.new('bolt://neo4j:pass@localhost:7687', options)

    # or

    require 'neo4j/core/cypher_session/adaptors/embedded'
    neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::Embedded.new('/file/path/to/graph.db', options)

The options are specific to each adaptor.  See below for details.

Once you have an adaptor you can create a session like so:

    neo4j_session = Neo4j::Core::CypherSession.new(http_adaptor)

From there you can make queries with a Cypher string:

    # Basic query
    neo4j_session.query('MATCH (n) RETURN n LIMIT 10')

    # Query with parameters
    neo4j_session.query('MATCH (n) RETURN n LIMIT {limit}', limit: 10)

Or via the `Neo4j::Core::Query` class

    query_obj = Neo4j::Core::Query.new.match(:n).return(:n).limit(10)

    neo4j_session.query(query_obj)

Making multiple queries with one request is supported with the HTTP Adaptor:

    results = neo4j_session.queries do
      append 'MATCH (n:Foo) RETURN n LIMIT 10'
      append 'MATCH (n:Bar) RETURN n LIMIT 5'
    end

    results[0] # results of first query
    results[1] # results of second query

When doing batched queries, there is also a shortcut for getting a new `Neo4j::Core::Query`:

    results = neo4j_session.queries do
      append query.match(:n).return(:n).limit(10)
    end

    results[0] # result

### Adaptor Options

As mentioned above, each of the adaptors take different sets of options.  They are enumerated below:

#### Shared options

All adaptors take `wrap_level` as an option.  This can be used to control how nodes, relationships, and path data is returned:

 * `wrap_level: :none` will return Ruby hashes
 * `wrap_level: :core_entity` will return objects from the `neo4j-core` gem (`Neo4j::Core::Node`, `Neo4j::Core::Relationship`, and `Neo4j::Core::Path`
 * `wrap_level: :prop` allows you to define Ruby Procs to do your own wrapping.  This is how the `neo4j` gem provides `ActiveNode` and `ActiveRel` objects (see the [`node_wrapper.rb`](https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/node_wrapper.rb) and [`rel_wrapper.rb`](https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/rel_wrapper.rb) files for examples on how this works

All adaptors will also take either a `logger` option with a Ruby logger to define where it will log to.

All adaptors will also take the `skip_instrumentation` option to skip logging of queries.

All adaptors will also take the `verbose_query_logs` option which can be `true` or `false` (`false` being the default).  This will change the logging to output the source line of code which caused a query to be executed (note that the `skip_instrumentation` should not be set for logging to be produced).

#### Bolt

The Bolt adaptor takes `connect_timeout`, `read_timeout`, and `write_timeout` options which define appropriate timeouts.  The `connect_timeout` is 10 seconds and the `read_timeout` and `write_timeout` are -1 (no timeout).  This is to cause the underlying `net_tcp_client` gem to operate in blocking mode (as opposed to non-blocking mode).  When using non-blocking mode problems were found and since the official Neo4j drivers in other languages use blocking mode, this is what this gem uses by default.  This issue could potentially be a bug in the handling of the `EAGAIN` signal, but it was not investigated further. Set the read/write timeouts at your own risk.

The Bolt adaptor also takes an `ssl` option which also corresponds to `net_tcp_client`'s `ssl` option (which, in turn, corresponds to Ruby's `OpenSSL::SSL::SSLContext`).  By default SSL is used.  For most cloud providers that use public certificate authorities this open generally won't be needed.  If you've setup Neo4j yourself you will need to provide the certificate like so:

```ruby
cert_store = OpenSSL::X509::Store.new
cert_store.add_file('/the/path/to/your/neo4j.cert')
ssl: {cert_store: cert_store}}
bolt_adaptor = Neo4j::Core::CypherSession::Adaptors::Bolt.new('bolt://neo4j:pass@localhost:7687', ssl: {cert_store: cert_store})
```

You can also turn SSL off by simply specifying `ssl: false`

#### HTTP

Since the HTTP adaptor uses the `faraday` gem under the covers, it takes a `faraday_configurator` option.  This allows you to pass in a `Proc` which works just like a Faraday setup block:

```ruby
  faraday_configurator: proc do |faraday|
    # The default configurator uses typhoeus so if you override the configurator you must specify this
    faraday.adapter :typhoeus
    # Optionally you can instead specify another adaptor
    # faraday.use Faraday::Adapter::NetHttpPersistent

    # If you need to set options which would normally be the second argument of `Faraday.new`, you can do the following:
    faraday.options[:open_timeout] = 5
    faraday.options[:timeout] = 65
    # faraday.options[:ssl] = { verify: true }
  end
```

#### Embedded

The Embedded adaptor takes `properties_file` and `properties_map` options which are passed to `loadPropertiesFromFile` and `setConfig` on the `GraphDatabaseBuilder` class from the Neo4j Java API.

## Documentation

Our documentation on ReadTheDocs covers both the `neo4j` and `neo4j-core` gems:

 * http://neo4jrb.readthedocs.org/en/stable/


## Support

### Issues

[![Next Release](https://badge.waffle.io/neo4jrb/neo4j-core.png?label=Next%20Release&title=Next%20Release) ![In Progress](https://badge.waffle.io/neo4jrb/neo4j-core.png?label=In%20Progress&title=In%20Progress) ![In Master](https://badge.waffle.io/neo4jrb/neo4j-core.png?label=In%20Master&title=In%20Master)](https://waffle.io/neo4jrb/neo4j-core)

[![Post an issue](https://img.shields.io/badge/Bug%3F-Post%20an%20issue!-blue.svg)](https://waffle.io/neo4jrb/neo4j-core)


### Get Support

#### Documentation

All new documentation will be done via our [readthedocs](http://neo4jrb.readthedocs.org) site, though some old documentation has yet to be moved from our [wiki](https://github.com/neo4jrb/neo4j/wiki) (also there is the [neo4j-core wiki](https://github.com/neo4jrb/neo4j-core/wiki))

#### Contact Us

[![StackOverflow](https://img.shields.io/badge/StackOverflow-Ask%20a%20question!-blue.svg)](http://stackoverflow.com/questions/ask?tags=neo4j.rb+neo4j+ruby)  [![Gitter](https://img.shields.io/badge/Gitter-Join%20our%20chat!-blue.svg)](https://gitter.im/neo4jrb/neo4j?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)  [![Twitter](https://img.shields.io/badge/Twitter-Tweet%20with%20us!-blue.svg)](https://twitter.com/neo4jrb)


## Developers

### Original Author

* [Andreas Ronge](https://github.com/andreasronge)

### Current Maintainers

* [Brian Underwood](https://github.com/cheerfulstoic)
* [Chris Grigg](https://github.com/subvertallchris)

Consulting support? Contact [Chris](http://subvertallmedia.com/) and/or [Brian](http://www.brian-underwood.codes/)

## Contributing

Pull request with high test coverage and good [code climate](https://codeclimate.com/github/neo4jrb/neo4j-core) values will be accepted faster.
Notice, only JRuby can run all the tests (embedded and server db). To run tests with coverage: `rake coverage`.

## License
* Neo4j.rb - MIT, see the LICENSE file http://github.com/neo4jrb/neo4j-core/tree/master/LICENSE.
* Lucene -  Apache, see http://lucene.apache.org/java/docs/features.html
* Neo4j - Dual free software/commercial license, see http://neo4j.org/

Notice there are different license for the neo4j-community, neo4j-advanced and neo4j-enterprise jar gems.
Only the neo4j-community gem is by default required.
