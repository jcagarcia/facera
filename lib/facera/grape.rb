require_relative 'grape/entity_generator'
require_relative 'grape/endpoint_generator'
require_relative 'grape/api_generator'

module Facera
  module Grape
    class << self
      # Generate a Grape API for a specific facet
      def api_for(facet_name)
        APIGenerator.for_facet(facet_name)
      end
    end
  end
end
