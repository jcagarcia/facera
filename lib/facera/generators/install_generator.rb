if defined?(Rails)
  require 'rails/generators/base'

  module Facera
    module Generators
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path('../templates', __FILE__)

        desc "Install Facera in your Rails application"

        def create_directories
          empty_directory 'app/cores'
          empty_directory 'app/facets'
        end

        def create_initializer
          create_file 'config/initializers/facera.rb', <<~RUBY
            # Facera configuration
            Facera.configure do |config|
              # Base path for all APIs
              # config.base_path = '/api'

              # API version
              # config.version = 'v1'

              # Enable dashboard
              # config.dashboard = true

              # Custom facet paths
              # config.facet_path :external, '/v1'
              # config.facet_path :internal, '/internal/v1'

              # Disable specific facets
              # config.disable_facet :agent

              # Authentication handlers
              # config.authenticate :external do |request|
              #   token = request.headers['Authorization']
              #   User.find_by_token(token)
              # end
            end

            # Auto-mount all defined facets
            # This will discover and mount facets from app/facets/
            # Facera.auto_mount!
          RUBY
        end

        def show_readme
          say "\n"
          say "=" * 70
          say "Facera installed successfully!"
          say "=" * 70
          say "\nNext steps:"
          say "  1. Generate a core:  rails g facera:core payment"
          say "  2. Generate a facet: rails g facera:facet external --core=payment"
          say "  3. Start your server and visit /{audience}/api/v1/health"
          say "\nDocumentation: https://github.com/jcagarcia/facera"
          say "=" * 70 + "\n"
        end
      end
    end
  end
end
