package neo4j.rb;

import org.neo4j.graphdb.PathExpander;
import org.neo4j.graphdb.traversal.Evaluator;
import org.neo4j.graphdb.traversal.PathEvaluator;
import org.neo4j.graphdb.traversal.TraversalDescription;

/**
 * Since we can't call the Java method from JRuby we do it here instead.
 * see https://groups.google.com/forum/?fromgroups#!topic/jruby-users/gUrc5pBfCiM
 */
public class Adaptor {

    public static TraversalDescription callEvaluator(TraversalDescription td, Evaluator evaluator) {
        return td.evaluator(evaluator);
    }

    public static TraversalDescription callPathEvaluator(TraversalDescription td, PathEvaluator evaluator) {
        return td.evaluator(evaluator);
    }

    public static TraversalDescription expandPath(TraversalDescription td, PathExpander expander) {
        return td.expand(expander);
    }

}
