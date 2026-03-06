#!/usr/bin/env rackup
# Facera Multi-Facet API Server
# Run with: rackup -p 9292

require_relative 'payment_api'

# Mount APIs at different paths
use Rack::Reloader, 0

map '/external' do
  run Facera.api_for(:external)
end

map '/internal' do
  run Facera.api_for(:internal)
end

map '/' do
  run lambda { |env|
    [200, {'Content-Type' => 'application/json'}, [{
      message: 'Facera Multi-Facet API Server',
      version: Facera::VERSION,
      facets: {
        external: '/external',
        internal: '/internal'
      },
      endpoints: {
        health: {
          external: '/external/health',
          internal: '/internal/health'
        },
        payments: {
          create: 'POST /external/payments',
          get: 'GET /external/payments/:id',
          list: 'GET /external/payments',
          confirm: 'POST /internal/payments/:id/confirm',
          cancel: 'POST /internal/payments/:id/cancel'
        }
      }
    }.to_json]]
  }
end

puts "\n" + "=" * 80
puts "Facera Multi-Facet API Server"
puts "=" * 80
puts "\nAvailable endpoints:"
puts "  Root:            http://localhost:9292/"
puts "  External API:    http://localhost:9292/external/health"
puts "  Internal API:    http://localhost:9292/internal/health"
puts "\nExample requests:"
puts "  # Check health"
puts "  curl http://localhost:9292/external/health"
puts
puts "  # List payments"
puts "  curl http://localhost:9292/external/payments?limit=10"
puts
puts "  # Create a payment"
puts "  curl -X POST http://localhost:9292/external/payments \\"
puts "    -H 'Content-Type: application/json' \\"
puts "    -d '{\"amount\": 100.0, \"currency\": \"USD\","
puts "        \"merchant_id\": \"550e8400-e29b-41d4-a716-446655440000\","
puts "        \"customer_id\": \"6ba7b810-9dad-11d1-80b4-00c04fd430c8\"}'"
puts
puts "  # Get a payment"
puts "  curl http://localhost:9292/external/payments/550e8400-e29b-41d4-a716-446655440000"
puts
puts "  # Confirm a payment (internal API only)"
puts "  curl -X POST http://localhost:9292/internal/payments/550e8400-e29b-41d4-a716-446655440000/confirm"
puts "=" * 80 + "\n\n"
