module Facera
  class ErrorFormatter
    VERBOSITY_LEVELS = [:minimal, :detailed, :structured].freeze

    def initialize(verbosity = :minimal)
      @verbosity = verbosity.to_sym
      validate_verbosity!
    end

    def format(error)
      case @verbosity
      when :minimal
        format_minimal(error)
      when :detailed
        format_detailed(error)
      when :structured
        format_structured(error)
      end
    end

    private

    def validate_verbosity!
      unless VERBOSITY_LEVELS.include?(@verbosity)
        raise Error, "Invalid verbosity level '#{@verbosity}'. Valid levels: #{VERBOSITY_LEVELS.join(', ')}"
      end
    end

    def format_minimal(error)
      {
        error: error.class.name.split('::').last.gsub('Error', '').downcase,
        message: error.message
      }
    end

    def format_detailed(error)
      result = {
        error: error.class.name,
        message: error.message,
        timestamp: Time.now.iso8601
      }

      case error
      when ValidationError
        result[:validation_errors] = error.errors
      when InvariantError
        result[:invariant_errors] = error.invariant_errors
      end

      result[:backtrace] = error.backtrace.first(10) if error.backtrace

      result
    end

    def format_structured(error)
      result = {
        type: error.class.name.split('::').last,
        message: error.message,
        timestamp: Time.now.iso8601,
        severity: severity_for(error)
      }

      case error
      when ValidationError
        result[:details] = {
          validation_errors: error.errors.map { |e| { field: extract_field(e), message: e } }
        }
      when InvariantError
        result[:details] = {
          invariant_violations: error.invariant_errors
        }
      when NotFoundError
        result[:details] = { resource: extract_resource(error.message) }
      end

      result
    end

    def severity_for(error)
      case error
      when ValidationError, PreconditionError
        'warning'
      when UnauthorizedError
        'error'
      when NotFoundError
        'info'
      else
        'error'
      end
    end

    def extract_field(error_message)
      error_message.split(' ').first
    end

    def extract_resource(message)
      message.split(' ').first
    end
  end
end
