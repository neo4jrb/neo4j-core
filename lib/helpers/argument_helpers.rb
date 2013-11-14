module Neo4j
  module ArgumentHelpers
    def extract_session(args)
      if args.last.is_a?(Session::Rest) || args.last.is_a?(Session::Embedded)
        args.pop
      else
        Session.current
      end
    end
  end
end