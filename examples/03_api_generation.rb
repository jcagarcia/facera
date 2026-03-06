#!/usr/bin/env ruby
# Phase 3: Grape API Generation
# Demonstrates automatic REST API generation from Facera DSL

require_relative '../lib/facera'
require_relative 'server/cores/payment_core'
require_relative 'server/facets/external_facet'
require_relative 'server/facets/internal_facet'

puts "=" * 80
puts "Phase 3: Grape API Generation"
puts "=" * 80
puts

# Show core summary
core = Facera.find_core(:payment)
puts "Core: #{core.name}"
puts "  Entities: #{core.entities.count}"
puts "  Capabilities: #{core.capabilities.count}"
puts "  Invariants: #{core.invariants.count}"
puts

# Generate APIs for each facet
facets = [:external, :internal]

puts "Auto-Generated APIs:"
puts "-" * 80

facets.each do |facet_name|
  facet = Facera.find_facet(facet_name)
  api = Facera.api_for(facet_name)

  puts
  puts "#{facet_name.to_s.upcase} FACET"
  puts "  Description: #{facet.description}"
  puts "  Capabilities: #{facet.allowed_capabilities.count}/#{core.capabilities.count}"
  puts "  Error verbosity: #{facet.error_verbosity}"
  puts
  puts "  Generated Routes:"

  # Group routes by resource
  api.routes.group_by { |r| r.path.split('/')[1] }.each do |resource, routes|
    puts "    #{resource}:" if resource && !resource.empty?
    routes.each do |route|
      method = route.request_method.ljust(6)
      path = route.path.gsub('(.:format)', '')
      puts "      #{method} #{path}"
    end
  end
end

puts
puts "-" * 80
puts

# Show field visibility comparison
puts "Field Visibility Comparison:"
puts "-" * 80

entity = core.find_entity(:payment)
fields = entity.attributes.keys

printf "%-20s", "Field"
facets.each { |name| printf " %-10s", name.to_s.upcase }
puts

puts "-" * 80

fields.each do |field|
  printf "%-20s", field
  facets.each do |facet_name|
    facet = Facera.find_facet(facet_name)
    visibility = facet.field_visibility_for(:payment)
    visible = visibility && visibility.visible?(field)
    printf " %-10s", visible ? "✓" : "✗"
  end
  puts
end

puts
puts "-" * 80
puts

# Show capability access comparison
puts "Capability Access Comparison:"
puts "-" * 80

printf "%-20s", "Capability"
facets.each { |name| printf " %-10s", name.to_s.upcase }
puts

puts "-" * 80

core.capabilities.each do |cap_name, _|
  printf "%-20s", cap_name
  facets.each do |facet_name|
    facet = Facera.find_facet(facet_name)
    allowed = facet.capability_allowed?(cap_name)
    printf " %-10s", allowed ? "✓" : "✗"
  end
  puts
end

puts
puts "=" * 80
puts "Summary"
puts "=" * 80
puts
puts "From a single core definition, Facera automatically generated:"
puts "  - Multiple REST APIs (one per facet)"
puts "  - Field serialization based on visibility rules"
puts "  - Parameter validation from entity definitions"
puts "  - Error handling with facet-specific verbosity"
puts "  - OpenAPI-ready documentation"
puts
puts "Next: Run the server with 'cd examples/server && rackup'"
puts "=" * 80
