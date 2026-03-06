# Application Builder
# Constructs the Rack application with middleware and auto-mounted facets

module PaymentAPI
  class Application
    def self.build
      Rack::Builder.new do
        # Middleware
        use Rack::Reloader, 0 if ENV['RACK_ENV'] == 'development'
        use Rack::CommonLogger

        # Auto-mount all Facera facets
        Facera.auto_mount!(self)

        # Root endpoint with API information
        map '/' do
          run lambda { |env|
            [200, {'Content-Type' => 'application/json'}, [{
              name: 'Facera Payment API',
              version: Facera::VERSION,
              facets: Facera::Registry.facets.keys,
              endpoints: {
                root: '/',
                external_health: '/api/v1/health',
                internal_health: '/api/internal/v1/health',
                operator_health: '/api/operator/v1/health'
              }
            }.to_json]]
          }
        end
      end
    end
  end
end
