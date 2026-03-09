module Facera
  class Executor
    attr_reader :facet, :capability, :params, :context

    def self.run(facet:, capability:, params: {}, context: {})
      new(facet: facet, capability: capability, params: params, context: context).execute
    end

    def initialize(facet:, capability:, params: {}, context: {})
      @facet = facet.is_a?(Symbol) ? Registry.find_facet(facet) : facet
      @capability = capability.is_a?(Symbol) ? @facet.core.find_capability(capability) : capability
      @params = normalize_params(params)
      @context = context
    end

    def execute
      # Check if capability is allowed in this facet
      unless facet.capability_allowed?(capability.name)
        raise UnauthorizedError, "Capability '#{capability.name}' is not allowed in facet '#{facet.name}'"
      end

      # Validate parameters
      validate_params!

      # Apply facet scoping if present
      apply_scoping!

      # Check preconditions
      check_preconditions!

      # Execute the capability logic
      result = execute_capability

      # Validate invariants if result is an entity (not a collection or metadata structure)
      validate_invariants!(result) if should_validate_result?(result)

      result
    end

    private

    def normalize_params(params)
      # Convert string keys to symbols
      params.transform_keys(&:to_sym)
    end

    def validate_params!
      errors = capability.validate_params(params)

      raise ValidationError.new(errors) if errors.any?
    end

    def apply_scoping!
      return unless facet.has_scope_for?(capability.name)

      scope_block = facet.capability_scope(capability.name)
      scope_params = context_eval(&scope_block)

      # Merge scope params into params
      @params.merge!(scope_params) if scope_params.is_a?(Hash)
    end

    def check_preconditions!
      return if capability.preconditions.empty?

      unless capability.check_preconditions(build_context)
        raise PreconditionError, "Precondition failed for capability '#{capability.name}'"
      end
    end

    def execute_capability
      # Priority 1: Execute block defined inline
      if capability.has_execute_block?
        return execute_inline_block
      end

      # Priority 2: Call adapter if registered
      adapter = AdapterRegistry.get(facet.core.name)
      if adapter
        return execute_adapter(adapter)
      end

      # Fallback: Mock implementation
      execute_mock_implementation
    end

    def execute_inline_block
      # Execute the block defined in the capability
      context = build_context
      result = context.instance_exec(params, &capability.execute_block)

      # Apply field setters if result is a hash
      if result.is_a?(Hash) && capability.field_setters.any?
        capability.field_setters.each do |field, value|
          result[field] = value.is_a?(Proc) ? value.call : value
        end
      end

      result
    end

    def execute_adapter(adapter_class)
      adapter_instance = adapter_class.new

      # Call the appropriate adapter method
      case capability.type
      when :create
        adapter_instance.send("create_#{capability.entity_name}", params)
      when :get
        adapter_instance.send("get_#{capability.entity_name}", params)
      when :list
        adapter_instance.send("list_#{capability.entity_name}s", params)
      when :action
        # For actions, call the method by capability name
        adapter_instance.send(capability.name, params)
      when :update
        adapter_instance.send("update_#{capability.entity_name}", params)
      when :delete
        adapter_instance.send("delete_#{capability.entity_name}", params)
      end
    end

    def execute_mock_implementation
      # Fallback mock implementation (for testing/prototyping)
      case capability.type
      when :create
        create_result
      when :get
        get_result
      when :list
        list_result
      when :action
        action_result
      when :update
        update_result
      when :delete
        delete_result
      else
        {}
      end
    end

    def create_result
      # Mock created entity
      entity_attrs = params.dup
      entity_attrs[:id] = generate_id
      entity_attrs[:created_at] = Time.now
      entity_attrs
    end

    def get_result
      # Mock fetched entity
      base_data = mock_entity_data
      base_data[:id] = params[:id]  # Use the requested ID
      base_data
    end

    def list_result
      # Mock collection
      {
        data: [mock_entity_data],
        meta: {
          total: 1,
          limit: params[:limit] || 20,
          offset: params[:offset] || 0
        }
      }
    end

    def action_result
      # Mock entity after action
      result = get_result

      # Apply transitions
      if capability.transitions.any?
        result[:status] = capability.transitions.first
      end

      # Apply field setters
      capability.field_setters.each do |field, value|
        result[field] = value.is_a?(Proc) ? value.call : value
      end

      result
    end

    def update_result
      get_result.merge(params.except(:id))
    end

    def delete_result
      { success: true, id: params[:id] }
    end

    def should_validate_result?(result)
      return false unless result.is_a?(Hash)
      return false if capability.type == :list # List returns collection structure
      return false if capability.type == :delete # Delete returns success message
      return false unless capability.entity_name

      true
    end

    def validate_invariants!(result)
      return unless capability.entity_name

      entity = facet.core.find_entity(capability.entity_name)
      errors = entity.validate_data(result)

      # Also check core invariants
      invariant_errors = facet.core.validate_invariants(build_context(result))
      errors.concat(invariant_errors)

      raise InvariantError.new(invariant_errors) if invariant_errors.any?
      raise ValidationError.new(errors) if errors.any?
    end

    def build_context(data = {})
      # Create a context object with data that can be used in blocks
      Context.new(data.merge(params).merge(context))
    end

    def context_eval(&block)
      build_context.instance_eval(&block)
    end

    def generate_id
      require 'securerandom'
      SecureRandom.uuid
    end

    def mock_entity_data
      # Generate mock data based on entity definition
      return {} unless capability.entity_name

      entity = facet.core.find_entity(capability.entity_name)
      data = {
        id: generate_id,
        created_at: Time.now
      }

      entity.attributes.each do |name, attr|
        next if [:id, :created_at, :updated_at].include?(name)
        data[name] = mock_value_for_type(attr.type)
      end

      data
    end

    def mock_value_for_type(type)
      case type
      when :string then "sample"
      when :integer then 42
      when :money then 100.0
      when :uuid then generate_id
      when :enum then :pending
      when :boolean then true
      when :hash then {}
      when :array then []
      when :timestamp, :datetime then Time.now
      else nil
      end
    end
  end
end
