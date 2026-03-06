if defined?(Rails)
  require 'rails/generators/base'

  module Facera
    module Generators
      class FacetGenerator < Rails::Generators::NamedBase
        source_root File.expand_path('../templates', __FILE__)

        desc "Generate a new Facera facet"

        class_option :core, type: :string, required: true, desc: "The core this facet belongs to"

        def create_facet_file
          template 'facet.rb.tt', File.join('app/facets', "#{file_name}_facet.rb")
        end

        private

        def core_name
          options[:core]
        end
      end
    end
  end
end
