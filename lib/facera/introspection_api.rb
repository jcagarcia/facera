require 'grape'
require_relative 'introspection'
require_relative 'openapi_generator'

module Facera
  class IntrospectionAPI < ::Grape::API
    format :json

    desc 'Get complete introspection data'
    get :introspect do
      Facera::Introspection.inspect_all
    end

    desc 'Get all cores'
    get :cores do
      Facera::Introspection.inspect_cores
    end

    desc 'Get specific core'
    params do
      requires :name, type: Symbol, desc: 'Core name'
    end
    get 'cores/:name' do
      core = Facera::Introspection.inspect_core(params[:name].to_sym)
      error!('Core not found', 404) unless core
      core
    end

    desc 'Get all facets'
    get :facets do
      Facera::Introspection.inspect_facets
    end

    desc 'Get specific facet'
    params do
      requires :name, type: Symbol, desc: 'Facet name'
    end
    get 'facets/:name' do
      facet = Facera::Introspection.inspect_facet(params[:name].to_sym)
      error!('Facet not found', 404) unless facet
      facet
    end

    desc 'Get mounted configuration'
    get :mounted do
      Facera::Introspection.inspect_mounted
    end

    desc 'Get OpenAPI spec for all facets'
    get :openapi do
      Facera::OpenAPIGenerator.generate_all
    end

    desc 'Get OpenAPI spec for specific facet'
    params do
      requires :name, type: Symbol, desc: 'Facet name'
    end
    get 'openapi/:name' do
      begin
        Facera::OpenAPIGenerator.for_facet(params[:name].to_sym)
      rescue => e
        error!(e.message, 404)
      end
    end
  end
end
