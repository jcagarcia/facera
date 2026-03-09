# Facera Initializer
# Configure Facera behavior and facet paths.
#
# Facet paths are OPTIONAL. Facets are identified by audience name and grouped
# across cores. Paths are auto-derived as /{audience}/{version}:
#
#   public   -> /api/public/v1    (serves /payments and /refunds resources)
#   internal -> /api/internal/v1  (serves /payments and /refunds resources)
#   ops      -> /api/ops/v1       (serves /payments and /refunds resources)

Facera.configure do |config|
  # Base path prefix for all facet APIs
  config.base_path = '/api'

  # API version — used in the default path convention
  config.version = 'v1'

  # Enable/disable features
  config.dashboard = true
  config.generate_docs = true

  # Optional: override paths for any audience
  # config.facet_path :public, '/v2/public'

  # Disable audiences based on environment
  # config.disable_facet :ops unless ENV['ENABLE_OPS_API']

  # Authentication handlers (example — keyed by audience name)
  # config.authenticate :public do |request|
  #   token = request.headers['Authorization']&.sub(/^Bearer /, '')
  #   User.find_by_token(token)
  # end
  #
  # config.authenticate :internal do |request|
  #   service_token = request.headers['X-Service-Token']
  #   Service.verify_token(service_token)
  # end
end
