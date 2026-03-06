module Facera
  class Invariant
    attr_reader :name, :description, :block

    def initialize(name, description: nil, &block)
      @name = name.to_sym
      @description = description
      @block = block

      raise Error, "Invariant '#{name}' must have a block" unless @block
    end

    def validate(context)
      context.instance_eval(&block)
    rescue StandardError => e
      raise Error, "Invariant '#{name}' validation failed: #{e.message}"
    end

    def check(context)
      result = validate(context)
      return true if result

      false
    end
  end
end
