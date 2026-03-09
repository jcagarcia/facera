module Facera
  module Registry
    class << self
      def cores
        @cores ||= {}
      end

      # Facets stored under composite key "audience:core" to allow the same
      # audience name to be defined for multiple cores.
      # e.g. define_facet(:checkout, core: :payment) and
      #      define_facet(:checkout, core: :refund)  both register under :checkout.
      def facets
        @facets ||= {}
      end

      # Returns facets grouped by audience name.
      # { checkout: [<Facet name=:checkout core=:payment>, <Facet name=:checkout core=:refund>], ... }
      def facet_groups
        groups = {}
        facets.each_value do |facet|
          (groups[facet.name] ||= []) << facet
        end
        groups
      end

      def register_core(name, core)
        cores[name.to_sym] = core
      end

      def register_facet(name, core_name, facet)
        key = :"#{name}:#{core_name}"
        facets[key] = facet
      end

      def find_core(name)
        cores[name.to_sym] or raise Error, "Core '#{name}' not found"
      end

      # find_facet returns the first facet matching the audience name, or the
      # specific core variant when a composite key "audience:core" is given.
      def find_facet(name)
        key = name.to_sym
        return facets[key] if facets.key?(key)

        # Try by audience name alone (first match)
        facets.each_value { |f| return f if f.name == key }

        raise Error, "Facet '#{name}' not found"
      end

      def reset!
        @cores = {}
        @facets = {}
      end
    end
  end
end
