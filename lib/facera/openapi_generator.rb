module Facera
  class OpenAPIGenerator
    attr_reader :audience_name, :facets

    def initialize(audience_name)
      @audience_name = audience_name.to_sym
      @facets = Registry.facet_groups[@audience_name]
      raise "Audience #{audience_name} not found" unless @facets&.any?
    end

    def generate
      {
        openapi: '3.0.3',
        info: info_section,
        servers: servers_section,
        paths: paths_section,
        components: components_section
      }
    end

    private

    def info_section
      core_names = @facets.map { |f| f.core_name.to_s }.join(', ')
      {
        title: "#{@audience_name.to_s.capitalize} API",
        description: "#{@audience_name} audience API covering: #{core_names}",
        version: Facera::VERSION,
        contact: {
          name: 'Facera Framework'
        }
      }
    end

    def servers_section
      config = Facera.configuration
      base_path = config.base_path
      facet_path = config.path_for_facet(@audience_name)

      [{
        url: "#{base_path}#{facet_path}",
        description: "#{@audience_name.to_s.capitalize} API"
      }]
    end

    def paths_section
      paths = {}

      # Health endpoint
      core_names = @facets.map { |f| f.core_name.to_s }
      paths['/health'] = {
        get: {
          summary: 'Health check',
          tags: ['Health'],
          responses: {
            '200' => {
              description: 'Service is healthy',
              content: {
                'application/json' => {
                  schema: {
                    type: 'object',
                    properties: {
                      status: { type: 'string', example: 'ok' },
                      audience: { type: 'string', example: @audience_name.to_s },
                      cores: { type: 'array', items: { type: 'string' }, example: core_names },
                      timestamp: { type: 'string', format: 'date-time' }
                    }
                  }
                }
              }
            }
          }
        }
      }

      # Entity endpoints — one facet per core
      @facets.each do |facet|
        core = Registry.cores[facet.core_name]
        next unless core

        facet.field_visibilities.each do |entity_name, visibility|
          entity = core.entities[entity_name]

          # Collection endpoints
          collection_path = "/#{entity_name}s"
          paths[collection_path] ||= {}

          # POST (create)
          if facet_capability_allowed?(facet, "create_#{entity_name}")
            paths[collection_path][:post] = create_operation(entity_name, entity, visibility)
          end

          # GET (list)
          if facet_capability_allowed?(facet, "list_#{entity_name}s")
            paths[collection_path][:get] = list_operation(entity_name, entity, visibility)
          end

          # Single resource endpoints
          resource_path = "/#{entity_name}s/{id}"
          paths[resource_path] ||= {}

          # GET (retrieve)
          if facet_capability_allowed?(facet, "get_#{entity_name}")
            paths[resource_path][:get] = get_operation(entity_name, entity, visibility)
          end

          # Action endpoints
          core.capabilities.each do |cap_name, capability|
            next unless capability.type == :action
            next unless capability.entity_name == entity_name
            next unless facet_capability_allowed?(facet, cap_name)

            action_name = cap_name.to_s.sub("#{entity_name}_", '')
            action_path = "/#{entity_name}s/{id}/#{action_name}"

            paths[action_path] = {
              post: action_operation(cap_name, capability, entity, visibility)
            }
          end
        end
      end

      paths
    end

    def create_operation(entity_name, entity, visibility)
      {
        summary: "Create a new #{entity_name}",
        tags: [entity_name.to_s.capitalize],
        requestBody: {
          required: true,
          content: {
            'application/json' => {
              schema: request_schema(entity_name, entity, visibility)
            }
          }
        },
        responses: {
          '201' => {
            description: "#{entity_name.to_s.capitalize} created successfully",
            content: {
              'application/json' => {
                schema: response_schema(entity_name, entity, visibility)
              }
            }
          },
          '400' => error_response('Validation error'),
          '401' => error_response('Unauthorized')
        }
      }
    end

    def list_operation(entity_name, entity, visibility)
      {
        summary: "List #{entity_name}s",
        tags: [entity_name.to_s.capitalize],
        parameters: [
          { name: 'limit', in: 'query', schema: { type: 'integer', default: 20 }, description: 'Number of results' },
          { name: 'offset', in: 'query', schema: { type: 'integer', default: 0 }, description: 'Pagination offset' }
        ],
        responses: {
          '200' => {
            description: "List of #{entity_name}s",
            content: {
              'application/json' => {
                schema: {
                  type: 'array',
                  items: response_schema(entity_name, entity, visibility)
                }
              }
            }
          },
          '401' => error_response('Unauthorized')
        }
      }
    end

    def get_operation(entity_name, entity, visibility)
      {
        summary: "Get a #{entity_name}",
        tags: [entity_name.to_s.capitalize],
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }
        ],
        responses: {
          '200' => {
            description: "#{entity_name.to_s.capitalize} details",
            content: {
              'application/json' => {
                schema: response_schema(entity_name, entity, visibility)
              }
            }
          },
          '404' => error_response('Not found'),
          '401' => error_response('Unauthorized')
        }
      }
    end

    def action_operation(cap_name, capability, entity, visibility)
      action_name = cap_name.to_s.sub("#{capability.entity_name}_", '')

      {
        summary: "#{action_name.capitalize} a #{capability.entity_name}",
        tags: [capability.entity_name.to_s.capitalize],
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }
        ],
        requestBody: capability.required_params.any? || capability.optional_params.any? ? {
          content: {
            'application/json' => {
              schema: {
                type: 'object',
                properties: (capability.required_params + capability.optional_params)
                  .reject { |p| p == :id }
                  .map { |param| [param, { type: 'string' }] }
                  .to_h,
                required: capability.required_params.reject { |p| p == :id }
              }
            }
          }
        } : nil,
        responses: {
          '200' => {
            description: "#{capability.entity_name.to_s.capitalize} #{action_name}d successfully",
            content: {
              'application/json' => {
                schema: response_schema(capability.entity_name, entity, visibility)
              }
            }
          },
          '400' => error_response('Validation error'),
          '404' => error_response('Not found'),
          '401' => error_response('Unauthorized')
        }
      }.compact
    end

    def request_schema(entity_name, entity, visibility)
      properties = {}
      required = []

      entity.attributes.each do |attr_name, attr|
        next if attr.immutable? && attr_name != :id

        properties[attr_name] = attribute_to_schema(attr)
        required << attr_name if attr.required?
      end

      {
        type: 'object',
        properties: properties,
        required: required
      }
    end

    def response_schema(entity_name, entity, visibility)
      properties = {}
      visible_fields = visibility.visible_field_names(entity)

      visible_fields.each do |field_name|
        if entity.attributes[field_name]
          properties[field_name] = attribute_to_schema(entity.attributes[field_name])
        end
      end

      # Add computed fields
      visibility.computed_fields.each do |computed_name, _block|
        properties[computed_name] = { type: 'string', description: 'Computed field' }
      end

      {
        type: 'object',
        properties: properties
      }
    end

    def attribute_to_schema(attr)
      schema = { type: type_to_openapi(attr.type) }
      schema[:enum] = attr.enum_values if attr.enum_values.any?
      schema[:format] = 'uuid' if attr.type == :uuid
      schema[:format] = 'date-time' if attr.type == :datetime
      schema
    end

    def type_to_openapi(type)
      case type
      when :string, :text, :uuid then 'string'
      when :integer then 'integer'
      when :decimal, :money then 'number'
      when :boolean then 'boolean'
      when :datetime, :date then 'string'
      when :json, :jsonb then 'object'
      else 'string'
      end
    end

    def error_response(description)
      {
        description: description,
        content: {
          'application/json' => {
            schema: {
              type: 'object',
              properties: {
                error: { type: 'string' },
                message: { type: 'string' }
              }
            }
          }
        }
      }
    end

    def facet_capability_allowed?(facet, cap_name)
      facet.capability_allowed?(cap_name.to_sym)
    end

    def components_section
      {
        securitySchemes: {
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT'
          }
        }
      }
    end

    class << self
      def for_facet(audience_name)
        new(audience_name).generate
      end

      def generate_all
        Registry.facet_groups.map do |audience_name, _facets|
          [audience_name, for_facet(audience_name)]
        end.to_h
      end
    end
  end
end
