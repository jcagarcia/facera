# Introspection

Runtime introspection and OpenAPI generation for exploring your APIs.

---

## Overview

Facera provides powerful introspection capabilities:
- Explore cores, facets, and capabilities at runtime
- Auto-generate OpenAPI 3.0 specifications
- Programmatic and HTTP access

---

## Introspection API

### Full Introspection

Get complete system introspection:

```bash
GET /api/facera/introspect
```

**Response:**
```json
{
  "cores": [...],
  "facets": [...],
  "mounted": {...}
}
```

### Inspect Cores

List all cores:

```bash
GET /api/facera/cores
```

**Response:**
```json
[
  {
    "name": "payment",
    "entities": [
      {
        "name": "payment",
        "attributes": [
          {
            "name": "id",
            "type": "uuid",
            "required": false,
            "immutable": true
          },
          {
            "name": "amount",
            "type": "money",
            "required": true,
            "immutable": false
          }
        ]
      }
    ],
    "capabilities": [
      {
        "name": "create_payment",
        "type": "create",
        "entity": "payment",
        "required_params": ["amount", "currency"],
        "optional_params": ["description"]
      }
    ]
  }
]
```

Get specific core:

```bash
GET /api/facera/cores/payment
```

### Inspect Facets

List all facets:

```bash
GET /api/facera/facets
```

**Response:**
```json
[
  {
    "name": "external",
    "core": "payment",
    "description": "Public API for external clients",
    "field_visibilities": {
      "payment": ["id", "amount", "currency", "status"]
    },
    "allowed_capabilities": ["create_payment", "get_payment"],
    "error_verbosity": "minimal"
  }
]
```

Get specific facet:

```bash
GET /api/facera/facets/external
```

### Mounted Configuration

See what's actually mounted:

```bash
GET /api/facera/mounted
```

**Response:**
```json
{
  "external": {
    "path": "/api/v1",
    "endpoints": 4
  },
  "internal": {
    "path": "/api/internal/v1",
    "endpoints": 8
  }
}
```

---

## OpenAPI Generation

### All Facets

Get OpenAPI specs for all facets:

```bash
GET /api/facera/openapi
```

**Response:**
```json
{
  "external": {
    "openapi": "3.0.3",
    "info": {...},
    "paths": {...}
  },
  "internal": {
    "openapi": "3.0.3",
    "info": {...},
    "paths": {...}
  }
}
```

### Specific Facet

Get OpenAPI spec for one facet:

```bash
GET /api/facera/openapi/external
```

**Response:**
```json
{
  "openapi": "3.0.3",
  "info": {
    "title": "External API",
    "description": "Public API for external clients",
    "version": "0.1.0",
    "contact": {
      "name": "Facera Framework"
    }
  },
  "servers": [
    {
      "url": "/api/v1",
      "description": "External API"
    }
  ],
  "paths": {
    "/health": {
      "get": {
        "summary": "Health check",
        "tags": ["Health"],
        "responses": {
          "200": {
            "description": "Service is healthy",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "status": {"type": "string"},
                    "facet": {"type": "string"},
                    "core": {"type": "string"}
                  }
                }
              }
            }
          }
        }
      }
    },
    "/payments": {
      "post": {
        "summary": "Create a new payment",
        "tags": ["Payment"],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": {
                  "amount": {"type": "number"},
                  "currency": {"type": "string"}
                },
                "required": ["amount", "currency"]
              }
            }
          }
        },
        "responses": {
          "201": {
            "description": "Payment created successfully",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "id": {"type": "string", "format": "uuid"},
                    "amount": {"type": "number"},
                    "currency": {"type": "string"},
                    "status": {"type": "string"}
                  }
                }
              }
            }
          }
        }
      }
    },
    "/payments/{id}": {
      "get": {
        "summary": "Get a payment",
        "tags": ["Payment"],
        "parameters": [
          {
            "name": "id",
            "in": "path",
            "required": true,
            "schema": {"type": "string", "format": "uuid"}
          }
        ],
        "responses": {
          "200": {
            "description": "Payment details"
          }
        }
      }
    }
  },
  "components": {
    "securitySchemes": {
      "bearerAuth": {
        "type": "http",
        "scheme": "bearer",
        "bearerFormat": "JWT"
      }
    }
  }
}
```

---

## Programmatic Introspection

Use introspection in your Ruby code:

### Inspect All

```ruby
require 'facera'

# Full introspection
data = Facera::Introspection.inspect_all

puts data[:cores].count
puts data[:facets].count
```

### Inspect Cores

```ruby
# All cores
cores = Facera::Introspection.inspect_cores
cores.each do |core|
  puts "Core: #{core[:name]}"
  puts "  Entities: #{core[:entities].map { |e| e[:name] }}"
  puts "  Capabilities: #{core[:capabilities].map { |c| c[:name] }}"
end

# Specific core
core = Facera::Introspection.inspect_core(:payment)
puts core[:entities].first[:attributes]
```

### Inspect Facets

```ruby
# All facets
facets = Facera::Introspection.inspect_facets
facets.each do |facet|
  puts "Facet: #{facet[:name]}"
  puts "  Core: #{facet[:core]}"
  puts "  Capabilities: #{facet[:allowed_capabilities]}"
end

# Specific facet
facet = Facera::Introspection.inspect_facet(:external)
puts facet[:field_visibilities]
```

### Generate OpenAPI

```ruby
# For specific facet
openapi = Facera::OpenAPIGenerator.for_facet(:external)
File.write('openapi-external.json', JSON.pretty_generate(openapi))

# For all facets
specs = Facera::OpenAPIGenerator.generate_all
specs.each do |facet_name, spec|
  File.write("openapi-#{facet_name}.json", JSON.pretty_generate(spec))
end
```

---

## Use Cases

### 1. API Documentation

Generate OpenAPI specs and import into documentation tools:

```bash
curl http://localhost:9292/api/facera/openapi/external > openapi.json
```

Import into:
- Swagger UI
- Redoc
- Postman
- Insomnia

### 2. Client Generation

Generate TypeScript/Ruby clients from OpenAPI specs:

```bash
# TypeScript
openapi-generator generate \
  -i openapi.json \
  -g typescript-axios \
  -o clients/typescript

# Ruby
openapi-generator generate \
  -i openapi.json \
  -g ruby \
  -o clients/ruby
```

### 3. Testing

Introspect to build dynamic tests:

```ruby
RSpec.describe "API Completeness" do
  let(:facet) { Facera::Introspection.inspect_facet(:external) }

  it "has health endpoint" do
    expect(facet[:endpoints]).to include('/health')
  end

  it "exposes only allowed capabilities" do
    facet[:allowed_capabilities].each do |cap|
      # Test capability is accessible
    end
  end
end
```

### 4. Monitoring

Track API changes over time:

```ruby
# Store current state
current_spec = Facera::OpenAPIGenerator.for_facet(:external)
Redis.set('openapi:external:current', current_spec.to_json)

# Compare with previous
previous_spec = JSON.parse(Redis.get('openapi:external:previous'))
diff = OpenAPIDiff.compare(previous_spec, current_spec)

if diff.breaking_changes?
  alert("Breaking changes detected in external API")
end
```

### 5. Discovery

Let consumers explore your API:

```bash
# What facets are available?
curl http://localhost:9292/api/facera/facets

# What can I do with payments?
curl http://localhost:9292/api/facera/cores/payment

# Show me the complete API spec
curl http://localhost:9292/api/facera/openapi/external
```

---

## Configuration

### Enable/Disable Introspection

```ruby
Facera.configure do |config|
  config.introspection = true   # Enable
  config.introspection = false  # Disable
end
```

### Environment-Specific

```ruby
config.introspection = ENV['RACK_ENV'] != 'production'
```

### Custom Path

```ruby
config.introspection_path = '/meta'
```

Results in:
```
GET /api/meta/introspect
GET /api/meta/cores
GET /api/meta/facets
GET /api/meta/openapi
```

---

## Security Considerations

### Disable in Production

Introspection can reveal API structure:

```ruby
# Only enable in development/staging
config.introspection = ENV['RACK_ENV'] != 'production'
```

### Require Authentication

```ruby
config.authenticate :introspection do |request|
  # Require admin access
  admin_token = request.headers['X-Admin-Token']
  Admin.verify_token(admin_token) or raise Facera::UnauthorizedError
end
```

### Rate Limiting

```ruby
config.rate_limit :introspection, requests: 10, per: :minute
```

---

## Complete Example

```ruby
# Explore the API
require 'facera'
require 'json'

# What facets exist?
facets = Facera::Introspection.inspect_facets
puts "Available facets:"
facets.each do |facet|
  puts "  - #{facet[:name]}: #{facet[:description]}"
end

# What's in the external facet?
external = Facera::Introspection.inspect_facet(:external)
puts "\nExternal facet:"
puts "  Exposed entities: #{external[:field_visibilities].keys}"
puts "  Allowed capabilities: #{external[:allowed_capabilities]}"

# Generate OpenAPI spec
openapi = Facera::OpenAPIGenerator.for_facet(:external)
puts "\nOpenAPI spec:"
puts "  Title: #{openapi[:info][:title]}"
puts "  Endpoints: #{openapi[:paths].keys}"

# Save to file
File.write('openapi-external.json', JSON.pretty_generate(openapi))
puts "\n✓ Saved to openapi-external.json"
```

---

## Next Steps

- [Examples](Examples.md) - Complete working examples
- [Deployment](Deployment.md) - Production deployment guides
- [Architecture](Architecture.md) - Design principles and internals
