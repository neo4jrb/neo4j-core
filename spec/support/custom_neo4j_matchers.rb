module CustomNeo4jMatchers
  class BeCypher

    def initialize(expected)
      @expected = expected
    end

    def eval_dsl(target)
      @result ||= Neo4j::Cypher.new(&target).to_s
    end

    def matches?(target)
      eval_dsl(target) == @expected
    end

    def failure_message_for_should
      %Q[expected #{@result.inspect} to be "#{@expected}"]
    end

    def failure_message_for_should_not
      %Q[expected #{@result} not to be "#{@expected}"]
    end

    def description
      "be equal \"#{@expected}\""
    end
  end

  def be_cypher(expected)
    BeCypher.new(expected)
  end
end
