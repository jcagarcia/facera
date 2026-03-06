module Facera
  module Registry
    class << self
      def cores
        @cores ||= {}
      end

      def facets
        @facets ||= {}
      end

      def register_core(name, core)
        cores[name.to_sym] = core
      end

      def register_facet(name, facet)
        facets[name.to_sym] = facet
      end

      def find_core(name)
        cores[name.to_sym] or raise Error, "Core '#{name}' not found"
      end

      def find_facet(name)
        facets[name.to_sym] or raise Error, "Facet '#{name}' not found"
      end

      def reset!
        @cores = {}
        @facets = {}
      end
    end
  end
end
