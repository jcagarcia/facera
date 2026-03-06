module Facera
  class Introspection
    class << self
      def inspect_all
        {
          version: Facera::VERSION,
          cores: inspect_cores,
          facets: inspect_facets,
          mounted: inspect_mounted
        }
      end

      def inspect_cores
        Registry.cores.map do |name, core|
          {
            name: name,
            entities: core.entities.map { |entity_name, entity|
              {
                name: entity_name,
                attributes: entity.attributes.map { |attr_name, attr|
                  {
                    name: attr_name,
                    type: attr.type,
                    required: attr.required?,
                    immutable: attr.immutable?,
                    enum_values: attr.enum_values
                  }.compact
                },
                required_attributes: entity.attributes.select { |_, a| a.required? }.keys,
                immutable_attributes: entity.attributes.select { |_, a| a.immutable? }.keys
              }
            },
            capabilities: core.capabilities.map { |cap_name, cap|
              {
                name: cap_name,
                type: cap.type,
                entity: cap.entity_name,
                required_params: cap.required_params,
                optional_params: cap.optional_params,
                preconditions: cap.preconditions.count,
                validations: cap.validations.count,
                transitions_to: cap.transitions,
                sets_fields: cap.field_setters
              }.compact
            },
            invariants: core.invariants.map { |inv|
              {
                name: inv.name,
                description: inv.description
              }
            }
          }
        end
      end

      def inspect_facets
        Registry.facets.map do |name, facet|
          {
            name: name,
            core: facet.core_name,
            description: facet.description,
            exposures: facet.field_visibilities.map { |entity_name, visibility|
              {
                entity: entity_name,
                visible_fields: visibility.visible_fields,
                hidden_fields: visibility.hidden_fields,
                computed_fields: visibility.computed_fields.keys,
                field_aliases: visibility.field_aliases
              }
            },
            capabilities: {
              allowed: facet.capability_access.allowed_capabilities,
              denied: facet.capability_access.denied_capabilities,
              total: facet.capability_access.allowed_capabilities == :all ? 'all' : facet.capability_access.allowed_capabilities.count
            },
            scopes: facet.capability_access.scopes.keys,
            error_verbosity: facet.error_verbosity,
            format: facet.format,
            rate_limit: facet.rate_limit,
            audit_logging: facet.audit_enabled
          }
        end
      end

      def inspect_mounted
        return {} unless defined?(Facera::AutoMount)

        # This will be populated after auto_mount! is called
        {
          base_path: Facera.configuration.base_path,
          version: Facera.configuration.version,
          facets: Facera.configuration.instance_variable_get(:@facet_paths) || {}
        }
      end

      def inspect_core(core_name)
        core = Registry.cores[core_name]
        return nil unless core

        inspect_cores.find { |c| c[:name] == core_name }
      end

      def inspect_facet(facet_name)
        facet = Registry.facets[facet_name]
        return nil unless facet

        inspect_facets.find { |f| f[:name] == facet_name }
      end
    end
  end
end
