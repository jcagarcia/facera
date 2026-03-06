module Facera
  module DSL
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def define_core(name, &block)
        core = Core.new(name)
        core.instance_eval(&block) if block_given?
        Registry.register_core(name, core)
        core
      end

      def define_facet(name, core:, &block)
        facet = Facet.new(name, core: core)
        facet.instance_eval(&block) if block_given?
        Registry.register_facet(name, facet)
        facet
      end

      def cores
        Registry.cores
      end

      def facets
        Registry.facets
      end

      def find_core(name)
        Registry.find_core(name)
      end

      def find_facet(name)
        Registry.find_facet(name)
      end
    end
  end

  extend DSL::ClassMethods
end
