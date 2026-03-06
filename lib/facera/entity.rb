module Facera
  class Entity
    attr_reader :name, :attributes

    def initialize(name)
      @name = name.to_sym
      @attributes = {}
    end

    def attribute(name, type, **options)
      attr = Attribute.new(name, type, **options)
      @attributes[attr.name] = attr
    end

    def find_attribute(name)
      @attributes[name.to_sym]
    end

    def required_attributes
      @attributes.values.select(&:required?)
    end

    def immutable_attributes
      @attributes.values.select(&:immutable?)
    end

    def validate_data(data)
      errors = []

      # Check required attributes
      required_attributes.each do |attr|
        if data[attr.name].nil? && data[attr.name.to_s].nil?
          errors << "#{attr.name} is required"
        end
      end

      # Validate each provided attribute
      data.each do |key, value|
        attr = find_attribute(key)
        next unless attr

        unless attr.validate_value(value)
          errors << "#{key} has invalid value for type #{attr.type}"
        end
      end

      errors
    end
  end
end
