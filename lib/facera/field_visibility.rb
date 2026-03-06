module Facera
  class FieldVisibility
    attr_reader :entity_name, :visible_fields, :hidden_fields, :field_aliases, :computed_fields

    def initialize(entity_name)
      @entity_name = entity_name.to_sym
      @visible_fields = nil  # nil means all fields visible
      @hidden_fields = []
      @field_aliases = {}
      @computed_fields = {}
    end

    def fields(*field_names)
      if field_names.first == :all
        @visible_fields = :all
      else
        @visible_fields = field_names.map(&:to_sym)
      end
    end

    def hide(*field_names)
      @hidden_fields = field_names.map(&:to_sym)
    end

    def alias_field(source, as:)
      @field_aliases[source.to_sym] = as.to_sym
    end

    def computed(field_name, &block)
      raise Error, "Computed field '#{field_name}' must have a block" unless block_given?
      @computed_fields[field_name.to_sym] = block
    end

    def visible?(field_name)
      field_sym = field_name.to_sym

      # If explicitly hidden, not visible
      return false if @hidden_fields.include?(field_sym)

      # If visible_fields is nil or :all, visible (unless hidden)
      return true if @visible_fields.nil? || @visible_fields == :all

      # Otherwise check if in visible list
      @visible_fields.include?(field_sym)
    end

    def aliased_name(field_name)
      @field_aliases[field_name.to_sym] || field_name
    end

    def visible_field_names(entity)
      base_fields = if @visible_fields == :all || @visible_fields.nil?
                      entity.attributes.keys
                    else
                      @visible_fields
                    end

      # Filter out hidden fields
      base_fields.reject { |f| @hidden_fields.include?(f) }
    end

    def all_visible_fields(entity)
      base_fields = visible_field_names(entity)
      computed_field_names = @computed_fields.keys

      base_fields + computed_field_names
    end
  end
end
