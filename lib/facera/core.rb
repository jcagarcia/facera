module Facera
  class Core
    attr_reader :name, :entities, :capabilities, :invariants

    def initialize(name)
      @name = name.to_sym
      @entities = {}
      @capabilities = {}
      @invariants = {}
      @current_entity = nil
    end

    def entity(name, &block)
      entity_obj = Entity.new(name)
      @entities[name.to_sym] = entity_obj
      @current_entity = entity_obj

      entity_obj.instance_eval(&block) if block_given?

      @current_entity = nil
      entity_obj
    end

    def capability(name, type:, &block)
      capability_obj = Capability.new(name, type: type)
      @capabilities[name.to_sym] = capability_obj

      capability_obj.instance_eval(&block) if block_given?

      capability_obj
    end

    def invariant(name, description: nil, &block)
      invariant_obj = Invariant.new(name, description: description, &block)
      @invariants[name.to_sym] = invariant_obj
    end

    def find_entity(name)
      @entities[name.to_sym] or raise Error, "Entity '#{name}' not found in core '#{@name}'"
    end

    def find_capability(name)
      @capabilities[name.to_sym] or raise Error, "Capability '#{name}' not found in core '#{@name}'"
    end

    def find_invariant(name)
      @invariants[name.to_sym]
    end

    def validate_invariants(context)
      errors = []

      @invariants.each do |name, invariant|
        begin
          result = invariant.check(context)
          errors << "Invariant '#{name}' failed" unless result
        rescue Error => e
          errors << e.message
        end
      end

      errors
    end
  end
end
