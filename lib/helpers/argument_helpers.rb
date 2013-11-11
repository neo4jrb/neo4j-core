module Neo4j
  module ArgumentHelpers
    def extract_session(args)
      case args.last.class
      when Session::Rest, Session::Embedded
        args.pop
      else
        Session.current
      end
    end
  end
end