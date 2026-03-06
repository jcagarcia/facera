if defined?(Rails)
  module Facera
    class Railtie < Rails::Railtie
      railtie_name :facera

      config.facera = Facera.configuration

      # Auto-load facet and core definitions
      initializer "facera.load_definitions", before: :load_config_initializers do
        # Use Facera's loader for automatic discovery
        Facera.load_all!
      end

      # Auto-mount facets after initialization
      initializer "facera.auto_mount", after: :load_config_initializers do |app|
        # Check if user has created a facera initializer
        facera_initializer = Rails.root.join('config/initializers/facera.rb')

        if File.exist?(facera_initializer)
          # User has control via initializer, don't auto-mount unless they call it
          Rails.logger.info "Facera: Configuration found at config/initializers/facera.rb"
        else
          # No initializer, auto-mount with defaults
          if Registry.facets.any?
            Rails.logger.info "Facera: Auto-mounting #{Registry.facets.count} facets..."
            Facera.auto_mount!(app)
          end
        end
      end

      # Reload facets in development mode
      config.to_prepare do
        if Rails.env.development?
          Facera.load_all!
        end
      end

      # Add rake tasks
      rake_tasks do
        load 'facera/tasks/routes.rake'
      end

      # Add generators
      generators do
        require 'facera/generators/install_generator'
        require 'facera/generators/core_generator'
        require 'facera/generators/facet_generator'
      end
    end
  end
end
