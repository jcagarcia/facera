module Facera
  class Configuration
    attr_accessor :base_path, :version, :dashboard, :generate_docs, :introspection
    attr_reader :facet_paths, :disabled_facets, :authentication_handlers, :middleware_handlers

    def initialize
      @base_path = ''
      @version = 'v1'
      @dashboard = true
      @generate_docs = true
      @introspection = true
      @facet_paths = {}
      @disabled_facets = []
      @authentication_handlers = {}
      @middleware_handlers = {}
    end

    def facet_path(facet_name, path)
      @facet_paths[facet_name.to_sym] = path
    end

    def disable_facet(facet_name)
      @disabled_facets << facet_name.to_sym
    end

    def authenticate(facet_name, &block)
      raise Error, "Authentication block required for facet '#{facet_name}'" unless block_given?
      @authentication_handlers[facet_name.to_sym] = block
    end

    def middleware_for(facet_name, &block)
      raise Error, "Middleware block required for facet '#{facet_name}'" unless block_given?
      @middleware_handlers[facet_name.to_sym] = block
    end

    def path_for_facet(facet_name)
      @facet_paths[facet_name.to_sym] || default_path_for(facet_name)
    end

    def facet_enabled?(facet_name)
      !@disabled_facets.include?(facet_name.to_sym)
    end

    def authentication_handler_for(facet_name)
      @authentication_handlers[facet_name.to_sym]
    end

    def middleware_handler_for(facet_name)
      @middleware_handlers[facet_name.to_sym]
    end

    private

    # Derives a default path from the audience (facet group) name.
    #
    # Pattern: /{audience}/api/{version}
    #
    # Examples:
    #   :checkout  -> /checkout/api/v1
    #   :ledger    -> /ledger/api/v1
    #   :support   -> /support/api/v1
    #   :claims    -> /claims/api/v1
    def default_path_for(facet_name)
      "/#{facet_name}/api/#{@version}"
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
