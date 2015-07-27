# Neo4j-core [![Code Climate](https://codeclimate.com/github/neo4jrb/neo4j-core.png)](https://codeclimate.com/github/neo4jrb/neo4j-core) [![Build Status](https://travis-ci.org/neo4jrb/neo4j-core.png)](https://travis-ci.org/neo4jrb/neo4j-core) [![Coverage Status](https://coveralls.io/repos/neo4jrb/neo4j-core/badge.png?branch=master)](https://coveralls.io/r/neo4jrb/neo4j-core?branch=master) [![PullReview stats](https://www.pullreview.com/github/neo4jrb/neo4j-core/badges/master.svg?)](https://www.pullreview.com/github/neo4jrb/neo4j-core/reviews/master)

A simple Ruby wrapper around the Neo4j graph database that works with the server and embedded Neo4j API. This gem can be used both from JRuby and normal MRI.
It can be used standalone without the neo4j gem.

## Documentation

### 3.0+ Documentation:

 * http://neo4jrb.readthedocs.org/en/stable/
 * https://github.com/neo4jrb/neo4j-core/wiki

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

[![StackOverflow](https://img.shields.io/badge/StackOverflow-Ask%20a%20question!-blue.svg)](http://stackoverflow.com/questions/ask?tags=neo4j.rb+neo4j+ruby)  [![Gitter](https://img.shields.io/badge/Gitter-Join%20our%20chat!-blue.svg)](https://gitter.im/neo4jrb/neo4j?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)  [![Twitter](https://img.shields.io/badge/Twitter-Tweet%20with%20us!-blue.svg)](https://twitter.com/neo4jrb)  [![Mailing list](https://img.shields.io/badge/Mailing%20list-Mail%20us!-blue.svg)](https://groups.google.com/forum/#!forum/neo4jrb)


## Developers

### Original Author

* [Andreas Ronge](https://github.com/andreasronge)

### Current Maintainers

* [Brian Underwood](https://github.com/cheerfulstoic)
* [Chris Grigg](https://github.com/subvertallchris)

* Consulting support? Contact [Chris](http://subvertallmedia.com/) and/or [Brian](http://www.brian-underwood.codes/)

## Contributing

Pull request with high test coverage and good [code climate](https://codeclimate.com/github/neo4jrb/neo4j-core) values will be accepted faster.
Notice, only JRuby can run all the tests (embedded and server db). To run tests with coverage: `rake coverage`.

## License
* Neo4j.rb - MIT, see the LICENSE file http://github.com/neo4jrb/neo4j-core/tree/master/LICENSE.
* Lucene -  Apache, see http://lucene.apache.org/java/docs/features.html
* Neo4j - Dual free software/commercial license, see http://neo4j.org/

Notice there are different license for the neo4j-community, neo4j-advanced and neo4j-enterprise jar gems.
Only the neo4j-community gem is by default required.
