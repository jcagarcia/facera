module Facera
  class AutoMount
    attr_reader :app, :config, :mounted_facets

    def initialize(app = nil, config: {})
      @app = app || detect_app
      @config = Facera.configuration
      @mounted_facets = {}
      @logger = Logger.new($stdout)
    end

    def mount!
      log_header
      discover_definitions
      mount_facets
      mount_introspection if @config.introspection
      mount_dashboard if @config.dashboard
      log_summary
      @mounted_facets
    end

    private

    def log_header
      @logger.info "\n" + "=" * 80
      @logger.info "💎 Facera v#{Facera::VERSION} - Auto-Mounting"
      @logger.info "=" * 80
    end

    def discover_definitions
      # Use Facera's loader to auto-discover cores, adapters, and facets
      loader = Loader.new(logger: @logger)
      loader.load_all!

      @logger.info "\n📊 Found:"
      @logger.info "  Cores: #{Registry.cores.count}"
      @logger.info "  Adapters: #{AdapterRegistry.all.count}"
      @logger.info "  Facets: #{Registry.facets.count} (#{Registry.facet_groups.count} audiences)"
    end

    def mount_facets
      @logger.info "\n🚀 Mounting facets:"

      Registry.facet_groups.each do |audience_name, facets|
        next unless @config.facet_enabled?(audience_name)

        path = "#{@config.base_path}#{@config.path_for_facet(audience_name)}"
        api = Grape::APIGenerator.for_group(audience_name, facets)

        mount_api(api, path)

        @mounted_facets[audience_name] = {
          path: path,
          api: api,
          endpoints: api.routes.count,
          cores: facets.map(&:core_name)
        }

        cores_label = facets.map(&:core_name).join(', ')
        @logger.info "  ✓ #{audience_name.to_s.ljust(12)} → #{path.ljust(30)} (#{api.routes.count} endpoints, cores: #{cores_label})"
      end
    end

    def mount_introspection
      path = "#{@config.base_path}/facera"
      api = IntrospectionAPI

      mount_api(api, path)

      @logger.info "\n📚 Introspection API:"
      @logger.info "  ✓ Mounted at #{path}"
      @logger.info "  • #{path}/introspect - Full introspection"
      @logger.info "  • #{path}/cores - All cores"
      @logger.info "  • #{path}/facets - All facets"
      @logger.info "  • #{path}/openapi - OpenAPI specs"
    end

    def mount_api(api, path)
      if defined?(Rails)
        Rails.application.routes.draw do
          mount api => path
        end
      elsif @app.respond_to?(:map)
        # Rack app with map support
        @app.map(path) { run api }
      else
        # Simple rack app
        @app = Rack::URLMap.new(
          path => api,
          '/' => @app
        )
      end
    end

    def mount_dashboard
      require_relative 'dashboard_api'

      mount_api(DashboardAPI, '/facera')

      @logger.info "\n🎨 Dashboard:"
      @logger.info "  ✓ Mounted at /facera"
    end

    def log_summary
      @logger.info "\n" + "=" * 80
      @logger.info "✨ Facera ready! #{@mounted_facets.count} facets mounted"
      @logger.info "=" * 80 + "\n"
    end

    def detect_app
      if defined?(Rails)
        Rails.application
      elsif defined?(Sinatra::Application)
        Sinatra::Application
      else
        # Return a basic Rack builder
        Rack::Builder.new
      end
    end
  end

  class << self
    def auto_mount!(app = nil, config: {})
      AutoMount.new(app, config: config).mount!
    end
  end
end

require 'logger'
