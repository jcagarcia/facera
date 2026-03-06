module Facera
  module Grape
    class EndpointGenerator
      def self.generate_for(api_class, capability, facet)
        case capability.type
        when :create
          generate_create(api_class, capability, facet)
        when :get
          generate_get(api_class, capability, facet)
        when :update
          generate_update(api_class, capability, facet)
        when :delete
          generate_delete(api_class, capability, facet)
        when :list
          generate_list(api_class, capability, facet)
        when :action
          generate_action(api_class, capability, facet)
        end
      end

      private

      def self.generate_create(api_class, capability, facet)
        entity_name = capability.entity_name
        resource_name = entity_name.to_s.pluralize
        entity = facet.core.find_entity(entity_name)
        entity_class = EntityGenerator.for(entity, facet)

        # Pre-calculate param types
        param_types = {}
        capability.required_params.each do |param|
          param_types[param] = param_type_for(param, entity)
        end
        capability.optional_params.each do |param|
          param_types[param] = param_type_for(param, entity)
        end

        api_class.class_eval do
          desc "Create a #{entity_name}" do
            success entity_class
            failure [[400, 'Validation Error'], [401, 'Unauthorized']]
          end

          params do
            capability.required_params.each do |param|
              requires param, type: param_types[param]
            end

            capability.optional_params.each do |param|
              optional param, type: param_types[param]
            end
          end

          post do
            result = Executor.run(
              facet: facet,
              capability: capability,
              params: declared(params),
              context: { current_user: current_user }
            )

            present result, with: entity_class
          rescue Facera::ValidationError => e
            error!({ error: 'validation', errors: e.errors }, 400)
          rescue Facera::UnauthorizedError => e
            error!({ error: 'unauthorized', message: e.message }, 401)
          end
        end
      end

      def self.generate_get(api_class, capability, facet)
        entity_name = capability.entity_name
        resource_name = entity_name.to_s.pluralize
        entity = facet.core.find_entity(entity_name)
        entity_class = EntityGenerator.for(entity, facet)

        api_class.class_eval do
          desc "Get a #{entity_name}" do
            success entity_class
            failure [[404, 'Not Found'], [401, 'Unauthorized']]
          end

          params do
            requires :id, type: String, desc: "#{entity_name.to_s.capitalize} ID"
          end

          get ':id' do
            result = Executor.run(
              facet: facet,
              capability: capability,
              params: { id: params[:id] },
              context: { current_user: current_user }
            )

            present result, with: entity_class
          rescue Facera::NotFoundError => e
            error!({ error: 'not_found', message: e.message }, 404)
          rescue Facera::UnauthorizedError => e
            error!({ error: 'unauthorized', message: e.message }, 401)
          end
        end
      end

      def self.generate_list(api_class, capability, facet)
        entity_name = capability.entity_name
        resource_name = entity_name.to_s.pluralize
        entity = facet.core.find_entity(entity_name)
        collection_class = EntityGenerator.for_collection(entity, facet)

        api_class.class_eval do
          desc "List #{resource_name}" do
            success collection_class
            failure [[401, 'Unauthorized']]
          end

          params do
            optional :limit, type: Integer, default: 20, desc: 'Number of items to return'
            optional :offset, type: Integer, default: 0, desc: 'Number of items to skip'

            capability.filterable_params.each do |param|
              optional param, type: String, desc: "Filter by #{param}"
            end

            capability.optional_params.each do |param|
              next if [:limit, :offset].include?(param)
              optional param, type: String
            end
          end

          get do
            result = Executor.run(
              facet: facet,
              capability: capability,
              params: declared(params),
              context: { current_user: current_user }
            )

            present result, with: collection_class
          rescue Facera::UnauthorizedError => e
            error!({ error: 'unauthorized', message: e.message }, 401)
          end
        end
      end

      def self.generate_update(api_class, capability, facet)
        entity_name = capability.entity_name
        entity = facet.core.find_entity(entity_name)
        entity_class = EntityGenerator.for(entity, facet)

        # Pre-calculate param types
        param_types = {}
        capability.optional_params.each do |param|
          param_types[param] = param_type_for(param, entity)
        end

        api_class.class_eval do
          desc "Update a #{entity_name}" do
            success entity_class
            failure [[400, 'Validation Error'], [404, 'Not Found'], [401, 'Unauthorized']]
          end

          params do
            requires :id, type: String

            capability.optional_params.each do |param|
              optional param, type: param_types[param]
            end
          end

          patch ':id' do
            result = Executor.run(
              facet: facet,
              capability: capability,
              params: declared(params),
              context: { current_user: current_user }
            )

            present result, with: entity_class
          rescue Facera::ValidationError => e
            error!({ error: 'validation', errors: e.errors }, 400)
          rescue Facera::NotFoundError => e
            error!({ error: 'not_found', message: e.message }, 404)
          rescue Facera::UnauthorizedError => e
            error!({ error: 'unauthorized', message: e.message }, 401)
          end
        end
      end

      def self.generate_delete(api_class, capability, facet)
        entity_name = capability.entity_name

        api_class.class_eval do
          desc "Delete a #{entity_name}" do
            success { { success: Boolean, id: String } }
            failure [[404, 'Not Found'], [401, 'Unauthorized']]
          end

          params do
            requires :id, type: String
          end

          delete ':id' do
            result = Executor.run(
              facet: facet,
              capability: capability,
              params: { id: params[:id] },
              context: { current_user: current_user }
            )

            present result
          rescue Facera::NotFoundError => e
            error!({ error: 'not_found', message: e.message }, 404)
          rescue Facera::UnauthorizedError => e
            error!({ error: 'unauthorized', message: e.message }, 401)
          end
        end
      end

      def self.generate_action(api_class, capability, facet)
        entity_name = capability.entity_name
        action_name = capability.action_name || extract_action_name(capability.name)
        entity = facet.core.find_entity(entity_name)
        entity_class = EntityGenerator.for(entity, facet)

        # Pre-calculate param types
        param_types = {}
        capability.required_params.each do |param|
          next if param == :id
          param_types[param] = param_type_for(param, entity)
        end
        capability.optional_params.each do |param|
          param_types[param] = param_type_for(param, entity)
        end

        api_class.class_eval do
          desc "#{action_name.to_s.humanize} a #{entity_name}" do
            success entity_class
            failure [[400, 'Validation Error'], [404, 'Not Found'], [401, 'Unauthorized'], [422, 'Precondition Failed']]
          end

          params do
            requires :id, type: String

            capability.required_params.each do |param|
              next if param == :id
              requires param, type: param_types[param]
            end

            capability.optional_params.each do |param|
              optional param, type: param_types[param]
            end
          end

          post ":id/#{action_name}" do
            result = Executor.run(
              facet: facet,
              capability: capability,
              params: declared(params),
              context: { current_user: current_user }
            )

            present result, with: entity_class
          rescue Facera::ValidationError => e
            error!({ error: 'validation', errors: e.errors }, 400)
          rescue Facera::PreconditionError => e
            error!({ error: 'precondition', message: e.message }, 422)
          rescue Facera::NotFoundError => e
            error!({ error: 'not_found', message: e.message }, 404)
          rescue Facera::UnauthorizedError => e
            error!({ error: 'unauthorized', message: e.message }, 401)
          end
        end
      end

      def self.extract_action_name(capability_name)
        # Extract action from capability name like "confirm_payment" -> "confirm"
        name_parts = capability_name.to_s.split('_')
        name_parts[0...-1].join('_').to_sym
      end

      def self.param_type_for(param_name, entity)
        attr = entity.find_attribute(param_name)
        return String unless attr

        case attr.type
        when :string, :uuid then String
        when :integer then Integer
        when :float, :money then Float
        when :boolean then Boolean
        when :hash then Hash
        when :array then Array
        else String
        end
      end
    end
  end
end

# Add humanize method if not available
unless String.method_defined?(:humanize)
  class String
    def humanize
      self.gsub('_', ' ').capitalize
    end
  end
end

# Add pluralize method if not available
unless String.method_defined?(:pluralize)
  class String
    def pluralize
      return self if self.end_with?('s')
      "#{self}s"
    end
  end
end
