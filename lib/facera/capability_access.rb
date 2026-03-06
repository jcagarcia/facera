module Facera
  class CapabilityAccess
    attr_reader :allowed_capabilities, :denied_capabilities, :scopes

    def initialize
      @allowed_capabilities = :all
      @denied_capabilities = []
      @scopes = {}
    end

    def allow(*capability_names)
      if capability_names.first == :all
        @allowed_capabilities = :all
      else
        @allowed_capabilities = [] if @allowed_capabilities == :all
        @allowed_capabilities.concat(capability_names.map(&:to_sym))
      end
    end

    def deny(*capability_names)
      @denied_capabilities.concat(capability_names.map(&:to_sym))
    end

    def scope(capability_name, &block)
      raise Error, "Scope for '#{capability_name}' must have a block" unless block_given?
      @scopes[capability_name.to_sym] = block
    end

    def allowed?(capability_name)
      cap_sym = capability_name.to_sym

      # Check if explicitly denied
      return false if @denied_capabilities.include?(cap_sym)

      # Check if in allowed list
      if @allowed_capabilities == :all
        true
      else
        @allowed_capabilities.include?(cap_sym)
      end
    end

    def scope_for(capability_name)
      @scopes[capability_name.to_sym]
    end

    def has_scope?(capability_name)
      @scopes.key?(capability_name.to_sym)
    end

    def allowed_capability_names(core)
      if @allowed_capabilities == :all
        core.capabilities.keys - @denied_capabilities
      else
        @allowed_capabilities - @denied_capabilities
      end
    end
  end
end
