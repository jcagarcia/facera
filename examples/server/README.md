# Facera Payment API Server

A real-world example of a multi-facet API using Facera's auto-mounting feature.

## Structure

```
server/
├── config.ru                    # Rack server (just 15 lines!)
├── application.rb               # Application builder (34 lines)
├── config/
│   └── facera.rb               # Facera configuration (33 lines)
├── cores/
│   └── payment_core.rb         # Payment domain model
└── facets/
    ├── external_facet.rb       # Public API
    ├── internal_facet.rb       # Service-to-service API
    └── operator_facet.rb       # Admin/support API
```

**Clean separation:**
- `config.ru` - Just loads and runs (15 lines)
- `application.rb` - Builds the Rack app
- `config/facera.rb` - Facera configuration
- `cores/` and `facets/` - Auto-discovered!
- No manual requires needed!

## Quick Start

```bash
# Start the server
rackup -p 9292

# Or with specific environment
RACK_ENV=development rackup -p 9292
```

The server automatically:
1. Loads configuration from `config/facera.rb`
2. Discovers all cores in `cores/`
3. Discovers all facets in `facets/`
4. Mounts APIs at configured paths

## Configuration

All Facera configuration is in `config/facera.rb`:

```ruby
Facera.configure do |config|
  config.base_path = '/api'
  config.version = 'v1'

  # Custom paths
  config.facet_path :external, '/v1'
  config.facet_path :internal, '/internal/v1'

  # Conditional features
  config.disable_facet :operator unless ENV['ENABLE_OPERATOR_API']
end
```

### Environment-Based Configuration

```bash
# Disable operator API in production
ENABLE_OPERATOR_API=false rackup -p 9292

# Custom port
rackup -p 8080
```

## API Facets

### External API (Public)

**Path:** `/api/v1`
**Audience:** External clients, mobile apps, web browsers

```bash
# Health check
curl http://localhost:9292/api/v1/health

# Create payment
curl -X POST http://localhost:9292/api/v1/payments \
  -H 'Content-Type: application/json' \
  -d '{
    "amount": 100.0,
    "currency": "USD",
    "merchant_id": "550e8400-e29b-41d4-a716-446655440000",
    "customer_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
  }'

# Get payment (limited fields)
curl http://localhost:9292/api/v1/payments/{id}

# List payments
curl http://localhost:9292/api/v1/payments?limit=10
```

**Field Visibility:** 6/11 fields (secure)
**Capabilities:** Create, Read, List only
**Error Detail:** Minimal

### Internal API (Service-to-Service)

**Path:** `/api/internal/v1`
**Audience:** Internal microservices

```bash
# Health check
curl http://localhost:9292/api/internal/v1/health

# Get payment (all fields + computed)
curl http://localhost:9292/api/internal/v1/payments/{id}

# Confirm payment (internal only)
curl -X POST http://localhost:9292/api/internal/v1/payments/{id}/confirm

# Cancel payment (internal only)
curl -X POST http://localhost:9292/api/internal/v1/payments/{id}/cancel
```

**Field Visibility:** All fields + computed
**Capabilities:** Full access
**Error Detail:** Detailed

### Operator API (Admin/Support)

**Path:** `/api/operator/v1`
**Audience:** Support staff, admin tools

```bash
# Health check
curl http://localhost:9292/api/operator/v1/health

# Get payment with operator fields
curl http://localhost:9292/api/operator/v1/payments/{id}
# Includes: customer_name, merchant_name, time_in_current_state

# Full operation access
curl -X POST http://localhost:9292/api/operator/v1/payments/{id}/confirm
```

**Field Visibility:** All fields + admin computed
**Capabilities:** Full access
**Error Detail:** Detailed + structured

## Adding a New Facet

1. **Create the facet file** in `facets/`:

```ruby
# facets/partner_facet.rb
Facera.define_facet(:partner, core: :payment) do
  description "Partner integration API"

  expose :payment do
    fields :id, :amount, :status
  end

  allow_capabilities :get_payment, :list_payments
  error_verbosity :minimal
end
```

2. **Restart server** - that's it!

The new facet is **automatically**:
- ✓ Discovered from `facets/` directory
- ✓ Loaded into the registry
- ✓ Mounted at `/api/partner/v1`
- ✓ Documented in startup logs

No manual loading, no config changes needed!

(Optional) Configure custom path in `config/facera.rb`:
```ruby
config.facet_path :partner, '/partners/v1'
```

## Key Files Explained

### `config.ru` (15 lines)

Super simple - just loads the app and runs it:

```ruby
require_relative '../../lib/facera'
require_relative 'config/facera'
require_relative 'application'

run PaymentAPI::Application.build
```

### `application.rb` (34 lines)

Builds the Rack application with middleware and auto-mounted facets:
1. Middleware (Reloader, Logger)
2. Auto-mount all facets
3. Root endpoint with API info

### `config/facera.rb`

Single source of truth for Facera configuration.

## Deployment

This is a standard Rack application. Works with:

### Puma (recommended)

```ruby
# config/puma.rb
workers ENV.fetch('WEB_CONCURRENCY', 2)
threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
threads threads_count, threads_count

port ENV.fetch('PORT', 9292)
environment ENV.fetch('RACK_ENV', 'development')
```

```bash
puma -C config/puma.rb
```

### Unicorn

```ruby
# config/unicorn.rb
worker_processes 4
listen 9292
```

```bash
unicorn -c config/unicorn.rb
```

### Docker

```dockerfile
FROM ruby:3.2

WORKDIR /app
COPY Gemfile* ./
RUN bundle install

COPY . .

EXPOSE 9292
CMD ["rackup", "-o", "0.0.0.0", "-p", "9292"]
```

## Production Considerations

### 1. Authentication

Add authentication handlers in `config/facera.rb`:

```ruby
Facera.configure do |config|
  config.authenticate :external do |request|
    token = request.headers['Authorization']&.sub(/^Bearer /, '')
    User.find_by_token(token) or raise Facera::UnauthorizedError
  end

  config.authenticate :internal do |request|
    service_token = request.headers['X-Service-Token']
    Service.verify_token(service_token) or raise Facera::UnauthorizedError
  end
end
```

### 2. Rate Limiting

Already configured in `facets/external_facet.rb`:

```ruby
rate_limit requests: 1000, per: :hour
```

### 3. Monitoring

Enable audit logging (already on for internal/operator):

```ruby
audit_all_operations user: :current_user
```

### 4. Environment Variables

```bash
# Required
DATABASE_URL=postgresql://...
REDIS_URL=redis://...

# Optional
ENABLE_OPERATOR_API=true
RACK_ENV=production
PORT=9292
```

## Architecture Benefits

### Before Facera

```
3 separate APIs × 5 endpoints = 15 implementations
+ 3 serializers
+ 3 authentication systems
+ 3 sets of tests
= ~2000 lines of code
```

### With Facera

```
1 core definition
+ 3 facet files
+ 1 config file
= ~300 lines of code
```

**85% less code, 100% consistency guaranteed**

## Development Workflow

1. **Define domain model** in `cores/payment_core.rb`
2. **Create facet projections** in `facets/`
3. **Configure paths** in `config/facera.rb`
4. **Run** - APIs are auto-generated!

No route definitions, no serializer boilerplate, no duplication.

## Testing

```bash
# All facets respond
curl http://localhost:9292/api/v1/health
curl http://localhost:9292/api/internal/v1/health
curl http://localhost:9292/api/operator/v1/health

# Field visibility working
curl http://localhost:9292/api/v1/payments/{id}
# Returns: id, amount, currency, status (6 fields)

curl http://localhost:9292/api/internal/v1/payments/{id}
# Returns: all 11 fields + computed

# Access control working
curl -X POST http://localhost:9292/api/v1/payments/{id}/confirm
# 404 - not available in external facet

curl -X POST http://localhost:9292/api/internal/v1/payments/{id}/confirm
# 200 - available in internal facet
```

## Troubleshooting

### Facet not mounting?

Check auto-mount logs:
```
I, INFO -- : ✓ external → /api/v1 (4 endpoints)
```

### Wrong path?

Check `config/facera.rb` paths.

### Missing capabilities?

Check facet's `allow_capabilities` / `deny_capabilities`.

### Field not showing?

Check facet's `expose` block and field visibility rules.
