module Neo4j
  # Helpers for processing method arguments
  module ArgumentHelpers
    # Extracts a session from the array of arguments if one exists at the end
    #
    # == Parameters:
    # args::
    #   An array of arguments of any type
    #
    # == Returns:
    # A session if the last argument is a valid session and pops it out of args.
    # Otherwise it returns the current session.
    #
    def extract_session(args)
      if args.last.is_a?(Session::Rest) || args.last.is_a?(Session::Embedded)
        args.pop
      else
        Session.current
      end
    end
  end
end