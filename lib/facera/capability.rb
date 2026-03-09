module Facera
  class Capability
    attr_reader :name, :type, :entity_name, :required_params, :optional_params,
                :preconditions, :validations, :transitions, :field_setters, :action_name,
                :execute_block

    VALID_TYPES = [:create, :get, :update, :delete, :list, :action].freeze

    def initialize(name, type:)
      @name = name.to_sym
      @type = type.to_sym
      @entity_name = nil
      @required_params = []
      @optional_params = []
      @preconditions = []
      @validations = []
      @transitions = []
      @field_setters = {}
      @action_name = nil
      @execute_block = nil

      validate_type!
    end

    def entity(name)
      @entity_name = name.to_sym
    end

    def requires(*param_names)
      param_names.each do |param_name|
        @required_params << param_name.to_sym
      end
    end

    def optional(*param_names)
      param_names.each do |param_name|
        @optional_params << param_name.to_sym
      end
    end

    def precondition(&block)
      @preconditions << block
    end

    def validates(&block)
      @validations << block
    end

    def transitions_to(state)
      @transitions << state.to_sym
    end

    def sets(field_values)
      @field_setters.merge!(field_values)
    end

    def action(name)
      @action_name = name.to_sym
    end

    def returns(type)
      @return_type = type.to_sym
    end

    def execute(&block)
      @execute_block = block
    end

    def has_execute_block?
      !@execute_block.nil?
    end

    def filterable(*param_names)
      @filterable_params ||= []
      param_names.each do |param_name|
        @filterable_params << param_name.to_sym
      end
    end

    def filterable_params
      @filterable_params || []
    end

    def validate_params(params)
      errors = []

      # Check required parameters
      required_params.each do |param|
        if params[param].nil? && params[param.to_s].nil?
          errors << "#{param} is required"
        end
      end

      errors
    end

    def check_preconditions(context)
      preconditions.all? do |precondition|
        context.instance_eval(&precondition)
      end
    end

    def validate_business_rules(context)
      validations.all? do |validation|
        context.instance_eval(&validation)
      end
    end

    private

    def validate_type!
      unless VALID_TYPES.include?(type)
        raise Error, "Invalid capability type '#{type}'. Valid types: #{VALID_TYPES.join(', ')}"
      end
    end
  end
end
