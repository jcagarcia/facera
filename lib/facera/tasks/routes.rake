namespace :facera do
  desc "Show all Facera routes"
  task routes: :environment do
    puts "\n" + "=" * 80
    puts "Facera Routes"
    puts "=" * 80

    if Facera::Registry.facets.empty?
      puts "\nNo facets defined."
      puts "Create facets in app/facets/ or use 'rails g facera:facet NAME --core=CORE'"
      puts "=" * 80 + "\n"
      next
    end

    Facera::Registry.facets.each do |name, facet|
      config = Facera.configuration
      next unless config.facet_enabled?(name)

      path_prefix = "#{config.base_path}#{config.path_for_facet(name)}"
      api = Facera::Grape::APIGenerator.for_facet(name)

      puts "\n#{name.to_s.upcase} (#{facet.description})"
      puts "  Base: #{path_prefix}"
      puts "  Capabilities: #{facet.allowed_capabilities.count}/#{facet.core.capabilities.count}"
      puts "  Routes:"

      # Group routes by resource
      api.routes.group_by { |r| r.path.split('/')[1] }.each do |resource, routes|
        routes.each do |route|
          method = route.request_method.ljust(7)
          path = "#{path_prefix}#{route.path.gsub('(.:format)', '')}"
          puts "    #{method} #{path}"
        end
      end
    end

    puts "\n" + "=" * 80 + "\n"
  end

  desc "Show Facera configuration"
  task config: :environment do
    config = Facera.configuration

    puts "\n" + "=" * 80
    puts "Facera Configuration"
    puts "=" * 80
    puts "\nGeneral:"
    puts "  Base path: #{config.base_path}"
    puts "  Version: #{config.version}"
    puts "  Dashboard: #{config.dashboard}"
    puts "  Generate docs: #{config.generate_docs}"

    puts "\nFacets:"
    puts "  Defined: #{Facera::Registry.facets.count}"
    puts "  Enabled: #{Facera::Registry.facets.count - config.disabled_facets.count}"
    puts "  Disabled: #{config.disabled_facets.join(', ')}" if config.disabled_facets.any?

    puts "\nCores:"
    puts "  Defined: #{Facera::Registry.cores.count}"
    Facera::Registry.cores.each do |name, core|
      puts "    #{name}: #{core.entities.count} entities, #{core.capabilities.count} capabilities"
    end

    puts "\n" + "=" * 80 + "\n"
  end
end
