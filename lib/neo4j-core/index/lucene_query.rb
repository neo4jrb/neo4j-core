module Neo4j
  module Core

    module Index
      # This object is returned when you call the #find method on the Node, Relationship.
      # The actual query is not executed until the first item is requested.
      #
      # You can perform a query in many different ways:
      #
      # @example By Hash
      #
      #  Person.find(:name => 'foo', :age => 3)
      #
      # @example By Range
      #
      #  Person.find(:age).between(15,35)
      #
      # @example By Lucene Query Syntax
      #
      #  Car.find('wheels:"4" AND colour: "blue")
      #
      # For more information about the syntax see http://lucene.apache.org/java/3_0_2/queryparsersyntax.html
      #
      # @example: By Compound Queries
      #
      #   Vehicle.find(:weight).between(5.0, 100000.0).and(:name).between('a', 'd')
      #
      # You can combine several queries by <tt>AND</tt>ing those together.
      #
      # @see Neo4j::Core::Index::Indexer#index
      # @see Neo4j::Core::Index::Indexer#find - which returns an LuceneQuery
      #
      class LuceneQuery
        include Enumerable
        attr_accessor :left_and_query, :left_or_query, :right_not_query, :query, :order

        def initialize(index, index_config, query, params={})
          @index = index
          @query = query
          @index_config = index_config
          @params = params
          @order = params[:sort] if params.include?(:sort)
        end

        # Implements the Ruby +Enumerable+ interface
        def each
          hits.each { |x| yield x.wrapper }
        end

        # Close hits
        #
        # Closes the underlying search result. This method should be called whenever you've got what you wanted from the result and won't use it anymore.
        # It's necessary to call it so that underlying indexes can dispose of allocated resources for this search result.
        # You can however skip to call this method if you loop through the whole result, then close() will be called automatically.
        # Even if you loop through the entire result and then call this method it will silently ignore any consequtive call (for convenience).
        #
        # This must be done according to the Neo4j Java Documentation:
        def close
          @hits.close if @hits
          @hits = nil
        end

        # @return [true, false] True if there is no search hits.
        def empty?
          hits.size == 0
        end

        # Does simply loop all search items till the n'th is found.
        # @return[Neo4j::Node, Neo4j::Relationship] the n'th search item
        def [](index)
          i = 0
          each { |x| return x if i == index; i += 1 }
          nil # out of index
        end

        # @return[Fixnum] the number of search hits
        def size
          hits.size
        end

        # Performs a range query
        # Notice that if you don't specify a type when declaring a property a String range query will be performed.
        #
        def between(lower, upper, lower_inclusive=false, upper_inclusive=false)
          raise "Expected a symbol. Syntax for range queries example: index(:weight).between(a,b)" unless Symbol === @query
          @query = range_query(@query, lower, upper, lower_inclusive, upper_inclusive)
          self
        end

        def range_query(field, lower, upper, lower_inclusive, upper_inclusive)
          type = @index_config.field_type(field)
          raise "no index on field #{field}" unless type
          # check that we perform a range query on the same values as we have declared with the property :key, :type => ...
          raise "find(#{field}).between(#{lower}, #{upper}): #{lower} not a #{type}" unless type == lower.class
          raise "find(#{field}).between(#{lower}, #{upper}): #{upper} not a #{type}" unless type == upper.class

          case lower
            when Fixnum
              Java::OrgApacheLuceneSearch::NumericRangeQuery.new_long_range(field.to_s, lower, upper, lower_inclusive, upper_inclusive)
            when Float
              Java::OrgApacheLuceneSearch::NumericRangeQuery.new_double_range(field.to_s, lower, upper, lower_inclusive, upper_inclusive)
            else
              Java::OrgApacheLuceneSearch::TermRangeQuery.new(field.to_s, lower, upper, lower_inclusive, upper_inclusive)
          end
        end


        # Create a compound lucene query.
        #
        # @param [String] query2 the query that should be AND together
        # @return [Neo4j::Core::Index::LuceneQuery] a new query object
        #
        # @example
        #
        #  Person.find(:name=>'kalle').and(:age => 3)
        #
        def and(query2)
          LuceneQuery.new(@index, @index_config, query2).tap { |new_query| new_query.left_and_query = self }
        end

        # Create an OR lucene query.
        #
        # @param [String] query2 the query that should be OR together
        # @return [Neo4j::Core::Index::LuceneQuery] a new query object
        #
        # @example
        #
        #  Person.find(:name=>'kalle').or(:age => 3)
        #
        def or(query2)
          LuceneQuery.new(@index, @index_config, query2).tap { |new_query| new_query.left_or_query = self }
        end

        # Create a NOT lucene query.
        #
        # @param [String] query2  the query that should exclude matching results
        # @return [Neo4j::Core::Index::LuceneQuery] a new query object
        #
        # @example
        #
        #  Person.find(:age => 3).not(:name=>'kalle')
        #
        def not(query2)
          LuceneQuery.new(@index, @index_config, query2).tap { |new_query| new_query.right_not_query = self }
        end


        # Sort descending the given fields.
        # @param [Symbol] fields it should sort
        def desc(*fields)
          @order ||= []
          @order += fields.map { |f| [f, :desc] }
          self
        end

        # Sort ascending the given fields.
        # @param [Symbol] fields it should sort
        def asc(*fields)
          @order ||= []
          @order += fields.map { |f| [f, :asc] }
          self
        end

        protected

        def parse_query(query)
          version = Java::OrgApacheLuceneUtil::Version::LUCENE_30
          analyzer = Java::OrgApacheLuceneAnalysisStandard::StandardAnalyzer.new(version)
          parser = Java::org.apache.lucene.queryParser.QueryParser.new(version, 'name', analyzer)
          parser.parse(query)
        end

        def build_and_query(query)
          build_composite_query(@left_and_query.build_query, query, Java::OrgApacheLuceneSearch::BooleanClause::Occur::MUST)
        end

        def build_or_query(query)
          build_composite_query(@left_or_query.build_query, query, Java::OrgApacheLuceneSearch::BooleanClause::Occur::SHOULD)
        end

        def build_not_query(query)
          right_query = @right_not_query.build_query
          query = parse_query(query) if query.is_a?(String)
          right_query = parse_query(right_query) if right_query.is_a?(String)

          composite_query = Java::OrgApacheLuceneSearch::BooleanQuery.new
          composite_query.add(query, Java::OrgApacheLuceneSearch::BooleanClause::Occur::MUST_NOT)
          composite_query.add(right_query, Java::OrgApacheLuceneSearch::BooleanClause::Occur::MUST)
          composite_query
        end

        def build_composite_query(left_query, right_query, operator) #:nodoc:
          left_query = parse_query(left_query) if left_query.is_a?(String)
          right_query = parse_query(right_query) if right_query.is_a?(String)
          composite_query = Java::OrgApacheLuceneSearch::BooleanQuery.new
          composite_query.add(left_query, operator)
          composite_query.add(right_query, operator)
          composite_query
        end

        def build_sort_query(query) #:nodoc:
          java_sort_fields = @order.inject([]) do |memo, val|
            field = val[0]
            field_type = @index_config.field_type(field)
            type = case
                     when Float == field_type
                       Java::OrgApacheLuceneSearch::SortField::DOUBLE
                     when Fixnum == field_type
                       Java::OrgApacheLuceneSearch::SortField::LONG
                     else
                       Java::OrgApacheLuceneSearch::SortField::STRING
                   end
            memo << Java::OrgApacheLuceneSearch::SortField.new(field.to_s, type, val[1] == :desc)
          end
          sort = Java::OrgApacheLuceneSearch::Sort.new(*java_sort_fields)
          Java::OrgNeo4jIndexLucene::QueryContext.new(query).sort(sort)
        end

        def build_hash_query(query) #:nodoc:
          and_query = Java::OrgApacheLuceneSearch::BooleanQuery.new

          query.each_pair do |key, value|
            type = @index_config.field_type(key)
            if type != String
              if Range === value
                and_query.add(range_query(key, value.first, value.last, true, !value.exclude_end?), Java::OrgApacheLuceneSearch::BooleanClause::Occur::MUST)
              elsif value.kind_of?(Enumerable)
                value.each do |v|
                  and_query.add(range_query(key, v, v, true, true), Java::OrgApacheLuceneSearch::BooleanClause::Occur::SHOULD)
                end
              else
                and_query.add(range_query(key, value, value, true, true), Java::OrgApacheLuceneSearch::BooleanClause::Occur::MUST)
              end
            else
              if value.kind_of?(Enumerable)
                value.each do |v|
                  term = Java::OrgApacheLuceneIndex::Term.new(key.to_s, v.to_s)
                  term_query = Java::OrgApacheLuceneSearch::TermQuery.new(term)
                  and_query.add(term_query, Java::OrgApacheLuceneSearch::BooleanClause::Occur::SHOULD)
                end
              else
                term = Java::OrgApacheLuceneIndex::Term.new(key.to_s, value.to_s)
                term_query = Java::OrgApacheLuceneSearch::TermQuery.new(term)
                and_query.add(term_query, Java::OrgApacheLuceneSearch::BooleanClause::Occur::MUST)
              end
            end
          end
          and_query
        end

        def build_query #:nodoc:
          query = @query
          query = build_hash_query(query) if Hash === query
          query = build_and_query(query) if @left_and_query
          query = build_or_query(query) if @left_or_query
          query = build_not_query(query) if @right_not_query
          query = build_sort_query(query) if @order
          query
        end

        def perform_query #:nodoc:
          @index.query(build_query)
        end


        def hits #:nodoc:
          close
          @hits = perform_query
        end


      end
    end
  end
end