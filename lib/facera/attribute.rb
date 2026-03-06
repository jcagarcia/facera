module Facera
  class Attribute
    attr_reader :name, :type, :options

    VALID_TYPES = [
      :string,
      :integer,
      :float,
      :boolean,
      :uuid,
      :money,
      :timestamp,
      :datetime,
      :date,
      :enum,
      :hash,
      :array
    ].freeze

    def initialize(name, type, **options)
      @name = name.to_sym
      @type = type.to_sym
      @options = options

      validate_type!
      validate_options!
    end

    def required?
      @options[:required] == true
    end

    def immutable?
      @options[:immutable] == true
    end

    def default_value
      @options[:default]
    end

    def enum_values
      @options[:values] || []
    end

    def validate_value(value)
      return true if value.nil? && !required?
      return false if value.nil? && required?

      case type
      when :string
        value.is_a?(String)
      when :integer
        value.is_a?(Integer)
      when :float
        value.is_a?(Float) || value.is_a?(Integer)
      when :boolean
        [true, false].include?(value)
      when :uuid
        value.is_a?(String) && uuid_format?(value)
      when :money
        value.is_a?(Numeric) && value >= 0
      when :timestamp, :datetime
        value.is_a?(Time) || value.is_a?(DateTime)
      when :date
        value.is_a?(Date)
      when :enum
        enum_values.include?(value)
      when :hash
        value.is_a?(Hash)
      when :array
        value.is_a?(Array)
      else
        true
      end
    end

    private

    def validate_type!
      unless VALID_TYPES.include?(type)
        raise Error, "Invalid attribute type '#{type}'. Valid types: #{VALID_TYPES.join(', ')}"
      end
    end

    def validate_options!
      if type == :enum && enum_values.empty?
        raise Error, "Enum attribute '#{name}' must specify :values option"
      end
    end

    def uuid_format?(value)
      value.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
    end
  end
end
