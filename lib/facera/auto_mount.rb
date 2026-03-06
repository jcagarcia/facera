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
      # Use Facera's loader to auto-discover cores and facets
      loader = Loader.new(logger: @logger)
      loader.load_all!

      @logger.info "\n📊 Found:"
      @logger.info "  Cores: #{Registry.cores.count}"
      @logger.info "  Facets: #{Registry.facets.count}"
    end

    def mount_facets
      @logger.info "\n🚀 Mounting facets:"

      Registry.facets.each do |name, facet|
        next unless @config.facet_enabled?(name)

        path = "#{@config.base_path}#{@config.path_for_facet(name)}"
        api = Grape::APIGenerator.for_facet(name)

        mount_api(api, path)

        @mounted_facets[name] = {
          path: path,
          api: api,
          endpoints: api.routes.count
        }

        @logger.info "  ✓ #{name.to_s.ljust(15)} → #{path.ljust(25)} (#{api.routes.count} endpoints)"
      end
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
      # Dashboard will be implemented in a future phase
      # For now, just log that it would be mounted
      @logger.info "\n  Dashboard: #{@config.base_path}/facera (coming soon)"
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
