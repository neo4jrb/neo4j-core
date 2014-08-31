# Neo4j-core v3.0 [![Code Climate](https://codeclimate.com/github/andreasronge/neo4j-core.png)](https://codeclimate.com/github/andreasronge/neo4j-core) [![Build Status](https://travis-ci.org/neo4jrb/neo4j-core.png)](https://travis-ci.org/andreasronge/neo4j-core) [![Coverage Status](https://coveralls.io/repos/neo4jrb/neo4j-core/badge.png?branch=master)](https://coveralls.io/r/neo4jrb/neo4j-core?branch=master)

A simple Ruby wrapper around the Neo4j graph database that works with the server and embedded Neo4j API. This gem can be used both from JRuby and normal MRI.
It can be used standalone without the neo4j gem.

## Documentation

* [3.0 Documentation](https://github.com/andreasronge/neo4j-core/wiki)
* [2.x Documentation](https://github.com/andreasronge/neo4j-core/tree/v2.x)


## Support

* [Neo4j.rb mailing list](https://groups.google.com/forum/#!forum/neo4jrb)
* Consulting support ? ask any of the developers

## Developers

* [Andreas Ronge](https://github.com/andreasronge)
* [Brian Underwood](https://github.com/cheerfulstoic)
* [Chris Grigg](https://github.com/subvertallchris)


## Contributing

Pull request with high test coverage and good [code climate](https://codeclimate.com/github/andreasronge/neo4j-core) values will be accepted faster.
Notice, only JRuby can run all the tests (embedded and server db). To run tests with coverage: `rake coverage`.

## License
* Neo4j.rb - MIT, see the LICENSE file http://github.com/andreasronge/neo4j-core/tree/master/LICENSE.
* Lucene -  Apache, see http://lucene.apache.org/java/docs/features.html
* \Neo4j - Dual free software/commercial license, see http://neo4j.org/

Notice there are different license for the neo4j-community, neo4j-advanced and neo4j-enterprise jar gems.
Only the neo4j-community gem is by default required.
