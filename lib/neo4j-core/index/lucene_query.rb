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

          if params.include?(:sort)
            @order = {}
            params[:sort].each_pair { |k, v| @order[k] = (v == :desc) }
          end
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
        def between(lower, upper, lower_incusive=false, upper_inclusive=false)
          raise "Expected a symbol. Syntax for range queries example: index(:weight).between(a,b)" unless Symbol === @query
#          raise "Can't only do range queries on Neo4j::NodeMixin, Neo4j::Model, Neo4j::RelationshipMixin" unless @decl_props
          # check that we perform a range query on the same values as we have declared with the property :key, :type => ...
          type = @index_config.decl_type_on(@query)
          raise "find(#{@query}).between(#{lower}, #{upper}): #{lower} not a #{type}" if type && !type === lower.class
          raise "find(#{@query}).between(#{lower}, #{upper}): #{upper} not a #{type}" if type && !type === upper.class

          # Make it possible to convert those values
          @query = range_query(@query, lower, upper, lower_incusive, upper_inclusive)
          self
        end

        def range_query(field, lower, upper, lower_incusive, upper_inclusive)
          lower = TypeConverters.convert(lower)
          upper = TypeConverters.convert(upper)

          case lower
            when Fixnum
              Java::OrgApacheLuceneSearch::NumericRangeQuery.new_long_range(field.to_s, lower, upper, lower_incusive, upper_inclusive)
            when Float
              Java::OrgApacheLuceneSearch::NumericRangeQuery.new_double_range(field.to_s, lower, upper, lower_incusive, upper_inclusive)
            else
              Java::OrgApacheLuceneSearch::TermRangeQuery.new(field.to_s, lower, upper, lower_incusive, upper_inclusive)
          end
        end


        # Create a compound lucene query.
        #
        # ==== Parameters
        # query2 :: the query that should be AND together
        #
        # ==== Example
        #
        #  Person.find(:name=>'kalle').and(:age => 3)
        #
        def and(query2)
          LuceneQuery.new(@index, @index_config, query2).tap { |new_query| new_query.left_and_query = self }
        end

        # Create an OR lucene query.
        #
        # ==== Parameters
        # query2 :: the query that should be OR together
        #
        # ==== Example
        #
        #  Person.find(:name=>'kalle').or(:age => 3)
        #
        def or(query2)
          LuceneQuery.new(@index, @index_config, query2).tap { |new_query| new_query.left_or_query = self }
        end

        # Create a NOT lucene query.
        #
        # ==== Parameters
        # query2 :: the query that should exclude matching results
        #
        # ==== Example
        #
        #  Person.find(:age => 3).not(:name=>'kalle')
        #
        def not(query2)
          LuceneQuery.new(@index, @index_config, query2).tap { |new_query| new_query.right_not_query = self }
        end


        # Sort descending the given fields.
        # @param [Symbol] fields it should sort
        def desc(*fields)
          @order = fields.inject(@order || {}) { |memo, field| memo[field] = true; memo }
          self
        end

        # Sort ascending the given fields.
        # @param [Symbol] fields it should sort
        def asc(*fields)
          @order = fields.inject(@order || {}) { |memo, field| memo[field] = false; memo }
          self
        end

        protected

        def build_and_query(query)
          build_composite_query(@left_and_query.build_query, query, Java::OrgApacheLuceneSearch::BooleanClause::Occur::MUST)
        end

        def build_or_query(query)
          build_composite_query(@left_or_query.build_query, query, Java::OrgApacheLuceneSearch::BooleanClause::Occur::SHOULD)
        end

        def build_not_query(query)
          right_query = @right_not_query.build_query
          composite_query = Java::OrgApacheLuceneSearch::BooleanQuery.new
          composite_query.add(query, Java::OrgApacheLuceneSearch::BooleanClause::Occur::MUST_NOT)
          composite_query.add(right_query, Java::OrgApacheLuceneSearch::BooleanClause::Occur::MUST)
          composite_query
        end

        def build_composite_query(left_query, right_query, operator) #:nodoc:
          composite_query = Java::OrgApacheLuceneSearch::BooleanQuery.new
          version = Java::OrgApacheLuceneUtil::Version::LUCENE_35
          analyzer = org.apache.lucene.analysis.standard::StandardAnalyzer.new(version)
          parser = Java::org.apache.lucene.queryParser.QueryParser.new(version,'name', analyzer )

          left_query = parser.parse(left_query) if left_query.is_a?(String)
          right_query = parser.parse(right_query) if right_query.is_a?(String)

          composite_query.add(left_query, operator)
          composite_query.add(right_query, operator)
          composite_query
        end

        def build_sort_query(query) #:nodoc:
          java_sort_fields = @order.keys.inject([]) do |memo, field|
            decl_type = @index_config.decl_type_on(field)
            type = case
                     when Float == decl_type
                       Java::OrgApacheLuceneSearch::SortField::DOUBLE
                     when Fixnum == decl_type || DateTime == decl_type || Date == decl_type || Time == decl_type
                       Java::OrgApacheLuceneSearch::SortField::LONG
                     else
                       Java::OrgApacheLuceneSearch::SortField::STRING
                   end
            memo << Java::OrgApacheLuceneSearch::SortField.new(field.to_s, type, @order[field])
          end
          sort = Java::OrgApacheLuceneSearch::Sort.new(*java_sort_fields)
          Java::OrgNeo4jIndexLucene::QueryContext.new(query).sort(sort)
        end

        def build_hash_query(query) #:nodoc:
          and_query = Java::OrgApacheLuceneSearch::BooleanQuery.new

          query.each_pair do |key, value|
            type = @index_config && @index_config[key.to_sym] && @index_config[key.to_sym][:type]
            if !type.nil? && type != String
              if Range === value
                and_query.add(range_query(key, value.first, value.last, true, !value.exclude_end?), Java::OrgApacheLuceneIndex::BooleanClause::Occur::MUST)
              else
                and_query.add(range_query(key, value, value, true, true), Java::OrgApacheLuceneIndex::BooleanClause::Occur::MUST)
              end
            else
              conv_value = type ? TypeConverters.convert(value) : value.to_s
              term = Java::OrgApacheLuceneIndex::Term.new(key.to_s, conv_value)
              term_query = Java::OrgApacheLuceneIndex::TermQuery.new(term)
              and_query.add(term_query, Java::OrgApacheLuceneIndex::BooleanClause::Occur::MUST)
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