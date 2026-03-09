# Configuration

Complete guide to configuring Facera for your application.

---

## Basic Configuration

```ruby
Facera.configure do |config|
  config.base_path = '/api'
  config.version = 'v1'
end
```

---

## Path Configuration

### Base Path

```ruby
config.base_path = '/api'
```

All facets will be mounted under this path.

### Version

```ruby
config.version = 'v1'
```

Default version for facets (unless overridden).

### Custom Facet Paths

```ruby
config.facet_path :external, '/v1'
config.facet_path :internal, '/internal/v1'
config.facet_path :operator, '/operator/v1'
config.facet_path :partner, '/partners/v2'
```

**Result:**
```
/api/v1                 (external)
/api/internal/v1        (internal)
/api/operator/v1        (operator)
/api/partners/v2        (partner)
```

---

## Authentication

### Bearer Token

```ruby
config.authenticate :external do |request|
  token = request.headers['Authorization']&.sub(/^Bearer /, '')
  user = User.find_by_token(token)
  raise Facera::UnauthorizedError unless user
  user
end
```

**Usage:**
```bash
curl -H 'Authorization: Bearer abc123' http://localhost:9292/api/v1/payments
```

### API Key

```ruby
config.authenticate :external do |request|
  api_key = request.headers['X-API-Key']
  client = ApiClient.find_by_key(api_key)
  raise Facera::UnauthorizedError unless client
  client
end
```

**Usage:**
```bash
curl -H 'X-API-Key: abc123' http://localhost:9292/api/v1/payments
```

### Service Token

```ruby
config.authenticate :internal do |request|
  service_token = request.headers['X-Service-Token']
  service = Service.verify_token(service_token)
  raise Facera::UnauthorizedError unless service
  service
end
```

### Admin Token

```ruby
config.authenticate :operator do |request|
  admin_token = request.headers['X-Admin-Token']
  admin = Admin.verify_token(admin_token)
  raise Facera::UnauthorizedError unless admin
  admin
end
```

### Multiple Authentication Methods

```ruby
config.authenticate :external do |request|
  # Try bearer token first
  if token = request.headers['Authorization']&.sub(/^Bearer /, '')
    user = User.find_by_token(token)
    return user if user
  end

  # Try API key
  if api_key = request.headers['X-API-Key']
    client = ApiClient.find_by_key(api_key)
    return client if client
  end

  raise Facera::UnauthorizedError
end
```

---

## Conditional Facets

### Environment-Based

```ruby
config.disable_facet :operator unless ENV['RACK_ENV'] == 'development'
config.disable_facet :internal unless ENV['ENABLE_INTERNAL_API']
```

### Feature Flag-Based

```ruby
config.disable_facet :partner unless FeatureFlag.enabled?(:partner_api)
```

### Custom Logic

```ruby
config.disable_facet :operator unless defined?(Rails) && Rails.env.development?
```

---

## Feature Flags

### Introspection

```ruby
config.introspection = true  # Enable introspection API
config.introspection = false # Disable in production
```

Controls:
- `GET /api/facera/introspect`
- `GET /api/facera/cores`
- `GET /api/facera/facets`

### Dashboard

```ruby
config.dashboard = true  # Enable dashboard UI
config.dashboard = false # Disable (default)
```

Controls:
- `GET /api/facera/ui` (coming soon)

### Documentation Generation

```ruby
config.generate_docs = true  # Generate OpenAPI specs
config.generate_docs = false # Disable
```

Controls:
- `GET /api/facera/openapi`
- `GET /api/facera/openapi/:facet`

---

## Complete Configuration Example

```ruby
# config/facera.rb
Facera.configure do |config|
  # Base configuration
  config.base_path = '/api'
  config.version = 'v1'

  # Custom facet paths
  config.facet_path :external, '/v1'
  config.facet_path :internal, '/internal/v1'
  config.facet_path :operator, '/operator/v1'
  config.facet_path :merchant, '/merchants/v1'

  # Authentication
  config.authenticate :external do |request|
    token = request.headers['Authorization']&.sub(/^Bearer /, '')
    User.find_by_token(token) or raise Facera::UnauthorizedError
  end

  config.authenticate :internal do |request|
    service_token = request.headers['X-Service-Token']
    Service.verify_token(service_token) or raise Facera::UnauthorizedError
  end

  config.authenticate :operator do |request|
    admin_token = request.headers['X-Admin-Token']
    Admin.verify_token(admin_token) or raise Facera::UnauthorizedError
  end

  config.authenticate :merchant do |request|
    api_key = request.headers['X-Merchant-Key']
    Merchant.find_by_api_key(api_key) or raise Facera::UnauthorizedError
  end

  # Conditional facets
  config.disable_facet :operator unless ENV['ENABLE_OPERATOR_API'] == 'true'
  config.disable_facet :merchant unless FeatureFlag.enabled?(:merchant_api)

  # Feature flags
  config.introspection = ENV['RACK_ENV'] != 'production'
  config.dashboard = ENV['RACK_ENV'] == 'development'
  config.generate_docs = true

  # Custom error handling
  config.error_handler do |error, facet|
    if error.is_a?(Facera::UnauthorizedError)
      Honeybadger.notify(error, context: { facet: facet })
    end
  end

  # Custom logging
  config.logger = Logger.new('log/facera.log')
  config.log_level = :info
end
```

---

## Environment-Specific Configuration

### Development

```ruby
# config/environments/development.rb
Facera.configure do |config|
  config.introspection = true
  config.dashboard = true
  config.generate_docs = true
  config.log_level = :debug
end
```

### Staging

```ruby
# config/environments/staging.rb
Facera.configure do |config|
  config.introspection = true
  config.dashboard = false
  config.generate_docs = true
  config.disable_facet :operator unless ENV['ENABLE_OPERATOR_API']
end
```

### Production

```ruby
# config/environments/production.rb
Facera.configure do |config|
  config.introspection = false
  config.dashboard = false
  config.generate_docs = true
  config.disable_facet :operator
  config.log_level = :warn
end
```

---

## Rails Configuration

### config/application.rb

```ruby
require 'facera'

module YourApp
  class Application < Rails::Application
    # Facera automatically integrates
  end
end
```

### config/initializers/facera.rb

```ruby
Facera.configure do |config|
  config.base_path = '/api'
  config.version = 'v1'

  config.authenticate :external do |request|
    token = request.headers['Authorization']&.sub(/^Bearer /, '')
    User.find_by_token(token) or raise Facera::UnauthorizedError
  end

  config.introspection = Rails.env.development?
  config.dashboard = Rails.env.development?
end
```

---

## Rack Configuration

### config.ru

```ruby
require 'facera'
require_relative 'config/facera'

app = Rack::Builder.new do
  use Rack::Reloader, 0 if ENV['RACK_ENV'] == 'development'
  use Rack::CommonLogger
  use Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: [:get, :post, :put, :delete]
    end
  end

  Facera.auto_mount!(self)
end

run app
```

### config/facera.rb

```ruby
Facera.configure do |config|
  config.base_path = '/api'
  config.version = 'v1'

  config.facet_path :external, '/v1'
  config.facet_path :internal, '/internal/v1'

  config.authenticate :external do |request|
    # Authentication logic
  end

  config.introspection = ENV['RACK_ENV'] != 'production'
  config.dashboard = false
end
```

---

## Best Practices

### 1. Separate Configuration Files

```
config/
├── facera.rb                 # Base configuration
└── environments/
    ├── development.rb        # Development overrides
    ├── staging.rb            # Staging overrides
    └── production.rb         # Production overrides
```

### 2. Use Environment Variables

```ruby
config.disable_facet :operator unless ENV['ENABLE_OPERATOR_API']
config.introspection = ENV['ENABLE_INTROSPECTION'] == 'true'
```

### 3. Secure Production

```ruby
if ENV['RACK_ENV'] == 'production'
  config.introspection = false
  config.dashboard = false
  config.disable_facet :operator
end
```

### 4. Centralize Authentication

```ruby
# lib/authentication.rb
module Authentication
  def self.verify_token(token)
    # Common authentication logic
  end
end

# config/facera.rb
config.authenticate :external do |request|
  token = request.headers['Authorization']&.sub(/^Bearer /, '')
  Authentication.verify_token(token) or raise Facera::UnauthorizedError
end
```

---

## Next Steps

- [Introspection](Introspection.md) - Runtime introspection and OpenAPI
- [Deployment](Deployment.md) - Production deployment guides
- [Examples](Examples.md) - Complete working examples
