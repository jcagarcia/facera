# Application Builder
# Constructs the Rack application with middleware and auto-mounted facets

module PaymentAPI
  class Application
    def self.build
      Rack::Builder.new do
        # Middleware
        use Rack::Reloader, 0 if ENV['RACK_ENV'] == 'development'
        use Rack::CommonLogger

        # Auto-mount all Facera facets and introspection API
        Facera.auto_mount!(self)
      end
    end
  end
end
