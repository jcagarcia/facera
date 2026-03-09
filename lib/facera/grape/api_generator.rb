require 'grape'

module Facera
  module Grape
    class APIGenerator
      # Generates a Grape API for a single facet (by audience name).
      # When multiple facets share the same audience name (different cores),
      # use for_group instead.
      def self.for_facet(facet_name)
        facet = Registry.find_facet(facet_name)
        for_group(facet.name, [facet])
      end

      # Generates a merged Grape API for a group of facets sharing the same
      # audience name. Each facet contributes its own core's resources under
      # separate resource routes (e.g. /payments, /refunds).
      def self.for_group(audience_name, facets)
        api_class = Class.new(::Grape::API) do
          format :json
          content_type :json, 'application/json'

          define_singleton_method(:facet_group) { facets }
          # Keep .facet for backwards compatibility when there is exactly one facet
          define_singleton_method(:facet) { facets.first }

          helpers do
            def current_user
              @current_user ||= { id: 'user-123' }
            end

            def current_facet
              self.class.facet
            end
          end

          # For each facet in the group, generate endpoints grouped by resource
          facets.each do |facet|
            core = facet.core

            # Collect resources across capabilities, deduplicating resource blocks
            resources_seen = {}

            facet.allowed_capabilities.each do |capability_name|
              capability = core.find_capability(capability_name)
              next unless capability&.entity_name

              resource_name = capability.entity_name.to_s.pluralize
              next if resources_seen[resource_name]

              resources_seen[resource_name] = true

              # Capture all capabilities for this resource
              resource_capabilities = facet.allowed_capabilities.select do |cn|
                cap = core.find_capability(cn)
                cap&.entity_name && cap.entity_name.to_s.pluralize == resource_name
              end

              resource resource_name do
                resource_capabilities.each do |cap_name|
                  cap = core.find_capability(cap_name)
                  EndpointGenerator.generate_for(self, cap, facet)
                end
              end
            end
          end

          get :health do
            {
              status: 'ok',
              audience: audience_name,
              cores: facets.map { |f| f.core_name },
              timestamp: Time.now.iso8601
            }
          end
        end

        api_class
      end
    end
  end
end
