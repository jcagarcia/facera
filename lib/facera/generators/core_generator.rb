if defined?(Rails)
  require 'rails/generators/base'

  module Facera
    module Generators
      class CoreGenerator < Rails::Generators::NamedBase
        source_root File.expand_path('../templates', __FILE__)

        desc "Generate a new Facera core"

        def create_core_file
          template 'core.rb.tt', File.join('app/cores', "#{file_name}_core.rb")
        end

        private

        def entity_name
          file_name.singularize
        end
      end
    end
  end
end
