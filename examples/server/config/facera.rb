# Facera Initializer
# Configure Facera behavior and facet paths

Facera.configure do |config|
  # Base path for all APIs
  config.base_path = '/api'

  # API version
  config.version = 'v1'

  # Custom paths for different facets
  config.facet_path :external, '/v1'           # /api/v1
  config.facet_path :internal, '/internal/v1'  # /api/internal/v1
  config.facet_path :operator, '/operator/v1'  # /api/operator/v1

  # Enable/disable features
  config.dashboard = false  # Not implemented yet
  config.generate_docs = true

  # Disable facets based on environment
  # config.disable_facet :operator unless ENV['ENABLE_OPERATOR_API']

  # Authentication handlers (example)
  # config.authenticate :external do |request|
  #   token = request.headers['Authorization']&.sub(/^Bearer /, '')
  #   User.find_by_token(token)
  # end
  #
  # config.authenticate :internal do |request|
  #   service_token = request.headers['X-Service-Token']
  #   Service.verify_token(service_token)
  # end
end
