require 'grape-entity'

module Facera
  module Grape
    class EntityGenerator
      def self.for(entity, facet)
        entity_name = entity.name
        visibility = facet.field_visibility_for(entity_name)

        # If no visibility rules, expose all fields
        unless visibility
          return create_default_entity(entity)
        end

        create_facet_entity(entity, visibility, facet)
      end

      def self.for_collection(entity, facet)
        entity_class = self.for(entity, facet)

        Class.new(::Grape::Entity) do
          expose :data, using: entity_class, documentation: { is_array: true }
          expose :meta do |obj, options|
            {
              total: obj[:total] || obj.dig(:meta, :total) || 0,
              limit: obj[:limit] || obj.dig(:meta, :limit) || 20,
              offset: obj[:offset] || obj.dig(:meta, :offset) || 0
            }
          end
        end
      end

      private

      def self.create_default_entity(entity)
        attrs = entity.attributes

        Class.new(::Grape::Entity) do
          attrs.each do |name, _attr|
            expose name
          end
        end
      end

      def self.create_facet_entity(entity, visibility, facet)
        visible_fields = visibility.visible_field_names(entity)
        aliases = visibility.field_aliases
        computed = visibility.computed_fields
        format_type = facet.format

        Class.new(::Grape::Entity) do
          # Expose visible base fields
          visible_fields.each do |field_name|
            aliased_name = aliases[field_name]

            if aliased_name
              # Field with alias
              expose field_name, as: aliased_name
            else
              # Regular field
              expose field_name
            end
          end

          # Expose computed fields
          computed.each do |field_name, block|
            expose field_name do |obj, options|
              context = build_computation_context(obj, options)
              context.instance_eval(&block)
            end
          end

          # Apply format-specific transformations
          if format_type == :structured
            format_with(:iso_timestamp) { |dt| dt&.iso8601 }
          end

          private

          def self.build_computation_context(obj, options)
            # Convert to Context to allow easy field access in blocks
            data = obj.is_a?(Hash) ? obj : {}
            Facera::Context.new(data.merge(options[:context] || {}))
          end
        end
      end
    end
  end
end
