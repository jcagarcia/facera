#!/usr/bin/env ruby
# Phase 4: Auto-Mounting System
# Demonstrates automatic facet discovery and mounting

require_relative '../lib/facera'
require_relative 'server/cores/payment_core'
require_relative 'server/facets/external_facet'
require_relative 'server/facets/internal_facet'

puts "=" * 80
puts "Phase 4: Auto-Mounting System"
puts "=" * 80
puts

# Show configuration options
puts "Configuration Options:"
puts "-" * 80
puts

puts "1. Default Configuration (zero-config):"
puts "   Facera.auto_mount!"
puts "   - Automatically discovers all facets"
puts "   - Mounts at conventional paths"
puts "   - No configuration required"
puts

puts "2. Custom Configuration:"
puts <<~CONFIG
   Facera.configure do |config|
     config.base_path = '/api'
     config.version = 'v2'

     # Custom facet paths
     config.facet_path :external, '/public/v2'
     config.facet_path :internal, '/services/v2'

     # Disable specific facets
     config.disable_facet :agent

     # Authentication per facet
     config.authenticate :external do |request|
       token = request.headers['Authorization']
       User.find_by_token(token)
     end
   end

   Facera.auto_mount!
CONFIG

puts "-" * 80
puts

# Demonstrate configuration
puts "Current Configuration:"
puts "-" * 80

config = Facera.configuration
puts "  Base path: #{config.base_path}"
puts "  Version: #{config.version}"
puts "  Dashboard: #{config.dashboard ? 'enabled' : 'disabled'}"
puts "  Generate docs: #{config.generate_docs ? 'enabled' : 'disabled'}"
puts

# Show what would be mounted
puts "Facets to be Mounted:"
puts "-" * 80

Facera::Registry.facets.each do |name, facet|
  next unless config.facet_enabled?(name)

  path = "#{config.base_path}#{config.path_for_facet(name)}"
  capabilities = facet.allowed_capabilities.count

  puts "  #{name.to_s.ljust(15)} → #{path.ljust(25)} (#{capabilities} capabilities)"
end

puts
puts "-" * 80
puts

# Demonstrate custom configuration
puts "Example: Custom Path Configuration"
puts "-" * 80

Facera.configure do |config|
  config.base_path = '/api'
  config.facet_path :external, '/v2'
  config.facet_path :internal, '/private/v2'
end

config = Facera.configuration

Facera::Registry.facets.each do |name, facet|
  next unless config.facet_enabled?(name)

  path = "#{config.base_path}#{config.path_for_facet(name)}"
  puts "  #{name.to_s.ljust(15)} → #{path}"
end

puts
puts "-" * 80
puts

# Reset to defaults
Facera.reset_configuration!

# Show Rails integration
puts "Rails Integration:"
puts "-" * 80
puts <<~RAILS

1. Install Facera:
   rails generate facera:install

2. Create directories automatically:
   app/cores/     - Core definitions
   app/facets/    - Facet definitions

3. Auto-loading:
   - Cores loaded from app/cores/**/*.rb
   - Facets loaded from app/facets/**/*.rb
   - Auto-mounted on Rails boot

4. Configuration (optional):
   config/initializers/facera.rb

5. Rake tasks:
   rake facera:routes   - Show all facet routes
   rake facera:config   - Show configuration

6. Generators:
   rails g facera:core payment
   rails g facera:facet external --core=payment

RAILS

puts "-" * 80
puts

# Show non-Rails integration
puts "Non-Rails (Rack) Integration:"
puts "-" * 80
puts <<~RACK

# config.ru
require 'facera'

# Define or require your cores and facets
require_relative 'app/cores/payment_core'
require_relative 'app/facets/external_facet'

# Auto-mount with Rack
app = Rack::Builder.new do
  # Your existing middleware
  use Rack::Logger

  # Let Facera mount all facets
  Facera.auto_mount!(self)
end

run app

RACK

puts "-" * 80
puts

puts "=" * 80
puts "Summary"
puts "=" * 80
puts
puts "Facera's auto-mounting provides:"
puts "  ✓ Zero-config facet discovery"
puts "  ✓ Conventional path mounting"
puts "  ✓ Rails automatic integration"
puts "  ✓ Rack/Sinatra support"
puts "  ✓ Custom path configuration"
puts "  ✓ Per-facet authentication"
puts "  ✓ Rake tasks for introspection"
puts
puts "Next: See it in action with 'cd examples/server && rackup'"
puts "=" * 80
