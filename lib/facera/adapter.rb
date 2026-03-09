module Facera
  # Base module for adapters
  # Adapters implement the actual business logic for capabilities
  #
  # Example:
  #   class PaymentAdapter
  #     include Facera::Adapter
  #
  #     def create_payment(params)
  #       Payment.create!(params)
  #     end
  #
  #     def get_payment(id:)
  #       Payment.find(id)
  #     end
  #   end
  module Adapter
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Returns the core name this adapter is for
      # Inferred from class name: PaymentAdapter -> :payment
      def core_name
        name.gsub(/Adapter$/, '').split('::').last.underscore.to_sym
      end
    end

    # Default implementation for capabilities
    # Subclasses override specific methods

    def create(params)
      raise NotImplementedError, "#{self.class}#create not implemented"
    end

    def get(id:)
      raise NotImplementedError, "#{self.class}#get not implemented"
    end

    def list(filters = {})
      raise NotImplementedError, "#{self.class}#list not implemented"
    end

    def action(capability_name, params)
      raise NotImplementedError, "#{self.class}#action(#{capability_name}) not implemented"
    end
  end

  # Adapter registry
  class AdapterRegistry
    @adapters = {}

    class << self
      def register(core_name, adapter_class)
        @adapters[core_name.to_sym] = adapter_class
      end

      def get(core_name)
        @adapters[core_name.to_sym]
      end

      def all
        @adapters
      end

      def clear!
        @adapters = {}
      end
    end
  end
end

# String underscore helper
class String
  def underscore
    gsub(/::/, '/')
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .tr('-', '_')
      .downcase
  end unless method_defined?(:underscore)
end
