require 'grape'

module Facera
  module Grape
    class APIGenerator
      def self.for_facet(facet_name)
        facet = Registry.find_facet(facet_name)
        core = facet.core

        api_class = Class.new(::Grape::API) do
          version 'v1', using: :header, vendor: 'facera'
          format :json
          content_type :json, 'application/json'

          # Store facet reference
          define_singleton_method(:facet) { facet }

          # Add helpers
          helpers do
            def current_user
              # Placeholder - in real implementation this would authenticate
              @current_user ||= { id: 'user-123' }
            end

            def current_facet
              self.class.facet
            end
          end

          # Generate endpoints for each allowed capability
          facet.allowed_capabilities.each do |capability_name|
            capability = core.find_capability(capability_name)
            next unless capability.entity_name

            entity_name = capability.entity_name
            resource_name = entity_name.to_s.pluralize

            # Create resource block
            resource resource_name do
              EndpointGenerator.generate_for(self, capability, facet)
            end
          end

          # Add a health check endpoint
          get :health do
            {
              status: 'ok',
              facet: facet.name,
              core: core.name,
              timestamp: Time.now.iso8601
            }
          end
        end

        api_class
      end
    end
  end
end
