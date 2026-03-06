module Facera
  class FaceraError < StandardError; end

  class ValidationError < FaceraError
    attr_reader :errors

    def initialize(errors)
      @errors = errors.is_a?(Array) ? errors : [errors]
      super(@errors.join(", "))
    end
  end

  class UnauthorizedError < FaceraError
    def initialize(message = "Unauthorized access")
      super(message)
    end
  end

  class NotFoundError < FaceraError
    def initialize(resource, id = nil)
      message = id ? "#{resource} with id '#{id}' not found" : "#{resource} not found"
      super(message)
    end
  end

  class PreconditionError < FaceraError
    def initialize(message = "Precondition failed")
      super(message)
    end
  end

  class InvariantError < FaceraError
    attr_reader :invariant_errors

    def initialize(invariant_errors)
      @invariant_errors = invariant_errors
      super("Invariant violations: #{invariant_errors.join(', ')}")
    end
  end
end
