module Facera
  class Loader
    attr_reader :load_paths, :logger

    def initialize(load_paths: nil, logger: nil)
      @load_paths = load_paths || detect_load_paths
      @logger = logger || Logger.new($stdout)
    end

    def load_all!
      load_cores!
      load_facets!
    end

    def load_cores!
      core_files = discover_files('cores')

      if core_files.any?
        @logger.info "📦 Loading cores..."
        core_files.each do |file|
          require file
          @logger.info "  ✓ #{File.basename(file, '.rb')}"
        end
      end

      core_files.count
    end

    def load_facets!
      facet_files = discover_files('facets')

      if facet_files.any?
        @logger.info "🎭 Loading facets..."
        facet_files.each do |file|
          require file
          @logger.info "  ✓ #{File.basename(file, '.rb')}"
        end
      end

      facet_files.count
    end

    private

    def detect_load_paths
      paths = []

      if defined?(Rails)
        # Rails application
        paths << Rails.root.to_s
      else
        # Non-Rails: look for conventional directories
        base_paths = [Dir.pwd, File.expand_path('..', Dir.pwd)]

        base_paths.each do |base|
          # Check if cores/ or facets/ exist at this level
          if File.directory?(File.join(base, 'cores')) ||
             File.directory?(File.join(base, 'facets'))
            paths << base
            break
          end

          # Check in app/ subdirectory
          app_path = File.join(base, 'app')
          if File.directory?(File.join(app_path, 'cores')) ||
             File.directory?(File.join(app_path, 'facets'))
            paths << app_path
            break
          end
        end
      end

      paths
    end

    def discover_files(type)
      files = []

      @load_paths.each do |base_path|
        # Try app/cores or app/facets (Rails-style)
        pattern = File.join(base_path, 'app', type, '**/*.rb')
        files.concat(Dir.glob(pattern))

        # Try cores/ or facets/ directly (non-Rails)
        pattern = File.join(base_path, type, '**/*.rb')
        files.concat(Dir.glob(pattern))

        # Try lib/cores or lib/facets
        pattern = File.join(base_path, 'lib', type, '**/*.rb')
        files.concat(Dir.glob(pattern))
      end

      files.uniq.sort
    end
  end

  class << self
    def load_all!(load_paths: nil)
      loader = Loader.new(load_paths: load_paths)
      loader.load_all!
    end

    def load_cores!(load_paths: nil)
      loader = Loader.new(load_paths: load_paths)
      loader.load_cores!
    end

    def load_facets!(load_paths: nil)
      loader = Loader.new(load_paths: load_paths)
      loader.load_facets!
    end
  end
end

require 'logger'
