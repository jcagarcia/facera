module Facera
  class Facet
    attr_reader :name, :core_name, :description, :field_visibilities, :capability_access,
                :error_verbosity, :format, :rate_limit, :audit_enabled

    def initialize(name, core:)
      @name = name.to_sym
      @core_name = core.to_sym
      @description = nil
      @field_visibilities = {}
      @capability_access = CapabilityAccess.new
      @error_verbosity = :minimal
      @format = :json
      @rate_limit = nil
      @audit_enabled = false
      @audit_options = {}
    end

    def core
      @core ||= Registry.find_core(@core_name)
    end

    def description(text = nil)
      return @description if text.nil?
      @description = text
    end

    def expose(entity_name, &block)
      visibility = FieldVisibility.new(entity_name)
      @field_visibilities[entity_name.to_sym] = visibility
      visibility.instance_eval(&block) if block_given?
      visibility
    end

    def allow_capabilities(*capability_names)
      @capability_access.allow(*capability_names)
    end

    def deny_capabilities(*capability_names)
      @capability_access.deny(*capability_names)
    end

    def scope(capability_name, &block)
      @capability_access.scope(capability_name, &block)
    end

    def error_verbosity(level = nil)
      return @error_verbosity if level.nil?
      @error_verbosity = level.to_sym
    end

    def format(format_type = nil)
      return @format if format_type.nil?
      @format = format_type.to_sym
    end

    def rate_limit(requests: nil, per: nil)
      return @rate_limit if requests.nil?
      @rate_limit = { requests: requests, per: per.to_sym }
    end

    def audit_all_operations(**options)
      @audit_enabled = true
      @audit_options = options
    end

    def field_visibility_for(entity_name)
      @field_visibilities[entity_name.to_sym]
    end

    def visible_fields_for(entity_name)
      visibility = field_visibility_for(entity_name)
      return [] unless visibility

      entity = core.entities[entity_name.to_sym]
      return [] unless entity
      visibility.all_visible_fields(entity)
    end

    def capability_allowed?(capability_name)
      @capability_access.allowed?(capability_name)
    end

    def capability_scope(capability_name)
      @capability_access.scope_for(capability_name)
    end

    def has_scope_for?(capability_name)
      @capability_access.has_scope?(capability_name)
    end

    def allowed_capabilities
      @capability_access.allowed_capability_names(core)
    end

    def error_formatter
      @error_formatter ||= ErrorFormatter.new(@error_verbosity)
    end

    def format_error(error)
      error_formatter.format(error)
    end
  end
end
