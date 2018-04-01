# Neo4j-core [![Code Climate](https://codeclimate.com/github/neo4jrb/neo4j-core.svg)](https://codeclimate.com/github/neo4jrb/neo4j-core) [![Build Status](https://travis-ci.org/neo4jrb/neo4j-core.svg)](https://travis-ci.org/neo4jrb/neo4j-core) [![Coverage Status](https://coveralls.io/repos/neo4jrb/neo4j-core/badge.svg?branch=master)](https://coveralls.io/r/neo4jrb/neo4j-core?branch=master) [![PullReview stats](https://www.pullreview.com/github/neo4jrb/neo4j-core/badges/master.svg?)](https://www.pullreview.com/github/neo4jrb/neo4j-core/reviews/master)

A simple Ruby wrapper around the Neo4j graph database that works with the server and embedded Neo4j API. This gem can be used both from JRuby and normal MRI.
It can be used standalone without the neo4j gem.

## Basic usage

### Executing Cypher queries

To make a basic connection to Neo4j to execute Cypher queries, first choose an adaptor.  Adaptors for HTTP, Bolt, and Embedded mode (jRuby only) are available.  You can create an adaptor like:

    http_adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new('http://neo4j:pass@localhost:7474')

    # or

    bolt_adaptor = Neo4j::Core::CypherSession::Adaptors::Bolt.new('bolt://neo4j:pass@localhost:7687', timeout: 10)

    # or

    neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::Embedded.new('/file/path/to/graph.db')

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

## Documentation

### 3.0+ Documentation:

 * http://neo4jrb.readthedocs.org/en/stable/

### 2.x Documentation

https://github.com/neo4jrb/neo4j-core/tree/v2.x

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
