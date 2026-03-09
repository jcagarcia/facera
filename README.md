<img src="img/facera.png" alt="Facera logo" width="250"/>

# Facera

**One semantic core. Multiple API facets. Zero duplication.**

Facera is a Ruby framework for building **multi-facet APIs** from a single semantic core. Define your domain model once, then expose different views for different consumers—external clients, internal services, operator tools, and automated agents—all guaranteed consistent by design.

[![Gem Version](https://badge.fury.io/rb/facera.svg)](https://badge.fury.io/rb/facera)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## Table of Contents

- [Why Facera?](#why-facera)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
- [Defining Cores](#defining-cores)
- [Defining Facets](#defining-facets)
- [API Generation](#api-generation)
- [Auto-Mounting](#auto-mounting)
- [Configuration](#configuration)
- [Introspection & Documentation](#introspection--documentation)
- [Examples](#examples)
- [Deployment](#deployment)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)

---

## Why Facera?

Modern systems expose APIs to many different consumers, often leading to:

- **Duplicated endpoints** for different audiences
- **Inconsistent representations** across APIs
- **Maintenance burden** keeping multiple APIs in sync
- **Scattered business logic** across different API layers

**Facera solves this** by letting you define your system **once** as a semantic core, then automatically generate multiple consistent API facets tailored to each consumer's needs.

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

**85% less code, 100% consistency guaranteed.**

---

## Installation

Add Facera to your Gemfile:

```ruby
gem 'facera'
```

Then run:

```bash
bundle install
```

Or install it directly:

```bash
gem install facera
```

---

## Quick Start

### 1. Define Your Core

Create a domain model with entities, capabilities, and invariants:

```ruby
# cores/payment_core.rb
Facera.define_core(:payment) do
  entity :payment do
    attribute :id, :uuid, immutable: true
    attribute :amount, :money, required: true
    attribute :currency, :string, required: true
    attribute :status, :enum, values: [:pending, :confirmed, :cancelled], required: true
    attribute :merchant_id, :uuid, required: true
    attribute :customer_id, :uuid, required: true
  end

  capability :create_payment, type: :create do
    entity :payment
    requires :amount, :currency, :merchant_id, :customer_id
    validates { amount > 0 }
  end

  capability :confirm_payment, type: :action do
    entity :payment
    requires :id
    precondition { status == :pending }
    transitions_to :confirmed
  end

  invariant :positive_amount, "Amount must be positive" do
    amount > 0
  end
end
```

### 2. Define Facets

Create different projections for different consumers:

```ruby
# facets/external_facet.rb
Facera.define_facet(:external, core: :payment) do
  description "Public API for external clients"

  expose :payment do
    fields :id, :amount, :currency, :status
  end

  allow_capabilities :create_payment
  error_verbosity :minimal
end
```

```ruby
# facets/internal_facet.rb
Facera.define_facet(:internal, core: :payment) do
  description "Service-to-service API"

  expose :payment do
    fields :all
    computed :processing_time do |payment|
      Time.now - payment.created_at
    end
  end

  allow_capabilities :all
  error_verbosity :detailed
  audit_all_operations user: :current_user
end
```

### 3. Mount and Run

```ruby
# config.ru
require 'facera'

Facera.configure do |config|
  config.base_path = '/api'
  config.version = 'v1'
end

app = Rack::Builder.new do
  Facera.auto_mount!(self)
end

run app
```

Start your server:

```bash
rackup -p 9292
```

That's it! You now have:
- ✅ `GET /api/v1/health` - External health check
- ✅ `POST /api/v1/payments` - Create payment (external)
- ✅ `GET /api/v1/payments/:id` - Get payment (limited fields)
- ✅ `GET /api/internal/v1/payments/:id` - Get payment (all fields)
- ✅ `POST /api/internal/v1/payments/:id/confirm` - Confirm payment (internal only)
- ✅ `GET /api/facera/introspect` - Full introspection
- ✅ `GET /api/facera/openapi/:facet` - OpenAPI specs

---

## Core Concepts

### The Facet Model

```
            Facet: external (limited fields, public)
                  │
Facet: agent ── Core ── Facet: internal (all fields, full access)
                  │
            Facet: operator (admin fields, audit logs)
```

The **core** defines the semantic meaning of your system. **Facets** project that meaning appropriately for different consumers.

### Core

The single source of truth for your domain model. Defines:

- **Entities**: Domain objects (payments, users, orders)
- **Capabilities**: Actions that can be performed
- **Invariants**: Business rules that must always hold
- **Transitions**: Valid state changes

### Facet

A consumer-specific projection that controls:

- **Field visibility**: Which entity fields are exposed
- **Capability access**: Which actions are available
- **Computed fields**: Additional derived data
- **Error verbosity**: How much detail to include in errors
- **Audit logging**: Whether to log operations

---

## Defining Cores

Cores define your domain model using a clean DSL:

### Entities

```ruby
Facera.define_core(:payment) do
  entity :payment do
    # Basic attributes
    attribute :id, :uuid, immutable: true
    attribute :amount, :money, required: true

    # Enum with validation
    attribute :status, :enum,
      values: [:pending, :confirmed, :cancelled],
      required: true

    # Timestamps
    attribute :created_at, :datetime
    attribute :confirmed_at, :datetime
  end
end
```

**Supported types:**
- `:string`, `:text`, `:integer`, `:float`, `:boolean`
- `:uuid`, `:money`, `:datetime`, `:date`
- `:enum`, `:hash`, `:array`

### Capabilities

Four types of capabilities:

#### 1. Create

```ruby
capability :create_payment, type: :create do
  entity :payment
  requires :amount, :currency, :merchant_id
  optional :description, :metadata

  validates do
    amount > 0 && currency.match?(/^[A-Z]{3}$/)
  end

  sets created_at: -> { Time.now }
end
```

#### 2. Get (Read Single)

```ruby
capability :get_payment, type: :get do
  entity :payment
  requires :id
end
```

#### 3. List (Read Multiple)

```ruby
capability :list_payments, type: :list do
  entity :payment
  optional :merchant_id, :customer_id, :status
  filterable :merchant_id, :customer_id, :status
end
```

#### 4. Action (State Transitions)

```ruby
capability :confirm_payment, type: :action do
  entity :payment
  requires :id
  optional :confirmation_code

  precondition do
    status == :pending
  end

  transitions_to :confirmed
  sets confirmed_at: -> { Time.now }
end
```

### Invariants

Business rules that must always be true:

```ruby
invariant :positive_amount, "Amount must be positive" do
  amount > 0
end

invariant :valid_transitions, "Only valid state transitions allowed" do
  valid_transition?(old_status, new_status)
end
```

---

## Defining Facets

Facets project your core for specific consumers:

### Field Visibility

```ruby
Facera.define_facet(:external, core: :payment) do
  expose :payment do
    # Explicit field list
    fields :id, :amount, :currency, :status

    # Or expose all fields
    fields :all

    # Hide specific fields
    hide :merchant_internal_id

    # Alias fields
    alias_field :amount, as: :total

    # Computed fields
    computed :display_amount do |payment|
      "#{payment.currency} #{payment.amount}"
    end
  end
end
```

### Capability Access Control

```ruby
Facera.define_facet(:external, core: :payment) do
  # Allow specific capabilities
  allow_capabilities :create_payment, :get_payment

  # Or allow all
  allow_capabilities :all

  # Deny specific capabilities
  deny_capabilities :delete_payment, :refund_payment
end
```

### Capability Scoping

Add automatic filtering to capabilities:

```ruby
Facera.define_facet(:merchant, core: :payment) do
  # Automatically filter by merchant
  scope :list_payments do |query|
    query.where(merchant_id: current_merchant.id)
  end

  scope :get_payment do |payment|
    payment if payment.merchant_id == current_merchant.id
  end
end
```

### Error Handling

Control error verbosity:

```ruby
Facera.define_facet(:external, core: :payment) do
  # Options: :minimal, :detailed, :structured
  error_verbosity :minimal
end
```

- **minimal**: Basic error messages only
- **detailed**: Stack traces and detailed errors
- **structured**: Full error objects with codes

### Additional Options

```ruby
Facera.define_facet(:external, core: :payment) do
  description "Public API for external clients"

  # Format
  format :json  # or :xml, :msgpack

  # Rate limiting
  rate_limit requests: 1000, per: :hour

  # Audit logging
  audit_all_operations user: :current_user, ip: :remote_ip
end
```

---

## API Generation

Facera automatically generates REST APIs using Grape:

### Generated Endpoints

For each exposed entity with allowed capabilities:

**Create**
```
POST /{entities}
```

**Get**
```
GET /{entities}/:id
```

**List**
```
GET /{entities}?filter1=value1&filter2=value2
```

**Actions**
```
POST /{entities}/:id/{action_name}
```

**Health**
```
GET /health
```

### Example Usage

```bash
# Create payment (external facet)
curl -X POST http://localhost:9292/api/v1/payments \
  -H 'Content-Type: application/json' \
  -d '{
    "amount": 100.0,
    "currency": "USD",
    "merchant_id": "550e8400-e29b-41d4-a716-446655440000",
    "customer_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
  }'

# Response (only exposed fields)
{
  "id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
  "amount": 100.0,
  "currency": "USD",
  "status": "pending"
}

# Get payment (internal facet - all fields)
curl http://localhost:9292/api/internal/v1/payments/7c9e6679-7425-40de-944b-e07fc1f90ae7

# Response (all fields + computed)
{
  "id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
  "amount": 100.0,
  "currency": "USD",
  "status": "pending",
  "merchant_id": "550e8400-e29b-41d4-a716-446655440000",
  "customer_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
  "created_at": "2026-03-07T00:00:00Z",
  "processing_time": 123.45
}

# Confirm payment (internal only)
curl -X POST http://localhost:9292/api/internal/v1/payments/7c9e6679-7425-40de-944b-e07fc1f90ae7/confirm

# Try to confirm via external (not allowed)
curl -X POST http://localhost:9292/api/v1/payments/7c9e6679-7425-40de-944b-e07fc1f90ae7/confirm
# 404 Not Found
```

---

## Auto-Mounting

Facera automatically discovers and mounts all facets with **zero configuration**:

### Convention Over Configuration

```
your_app/
├── cores/
│   ├── payment_core.rb
│   └── user_core.rb
└── facets/
    ├── external_facet.rb
    ├── internal_facet.rb
    └── operator_facet.rb
```

Facera automatically:
1. ✅ Discovers all `.rb` files in `cores/`, `app/cores/`, or `lib/cores/`
2. ✅ Discovers all `.rb` files in `facets/`, `app/facets/`, or `lib/facets/`
3. ✅ Loads them in the right order
4. ✅ Generates REST APIs
5. ✅ Mounts them at configured paths

### Basic Usage

```ruby
# config.ru or application.rb
Rack::Builder.new do
  use Rack::CommonLogger

  # That's it! Auto-discovers and mounts everything
  Facera.auto_mount!(self)
end
```

### With Middleware

```ruby
Rack::Builder.new do
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
```

### Startup Logs

```
💎 Facera v0.1.0 - Auto-Mounting
================================================================================
📦 Loading cores...
  ✓ payment_core
  ✓ user_core
🎭 Loading facets...
  ✓ external_facet
  ✓ internal_facet
  ✓ operator_facet

📊 Found:
  Cores: 2
  Facets: 3

🚀 Mounting facets:
  ✓ external        → /api/v1                   (4 endpoints)
  ✓ internal        → /api/internal/v1          (8 endpoints)
  ✓ operator        → /api/operator/v1          (8 endpoints)

📚 Introspection API:
  ✓ Mounted at /api/facera
  • /api/facera/introspect - Full introspection
  • /api/facera/cores - All cores
  • /api/facera/facets - All facets
  • /api/facera/openapi - OpenAPI specs

================================================================================
✨ Facera ready! 3 facets mounted
================================================================================
```

---

## Configuration

### Basic Configuration

```ruby
# config/facera.rb
Facera.configure do |config|
  config.base_path = '/api'
  config.version = 'v1'
end
```

### Custom Facet Paths

```ruby
Facera.configure do |config|
  config.facet_path :external, '/v1'
  config.facet_path :internal, '/internal/v1'
  config.facet_path :operator, '/operator/v1'
  config.facet_path :partner, '/partners/v2'
end
```

### Conditional Facets

```ruby
Facera.configure do |config|
  # Disable operator API in production
  config.disable_facet :operator unless ENV['ENABLE_OPERATOR_API']

  # Only enable partner facet for specific environments
  config.disable_facet :partner unless ENV['RACK_ENV'] == 'staging'
end
```

### Authentication

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

  config.authenticate :operator do |request|
    admin_token = request.headers['X-Admin-Token']
    Admin.verify_token(admin_token) or raise Facera::UnauthorizedError
  end
end
```

### Feature Flags

```ruby
Facera.configure do |config|
  # Enable/disable features
  config.introspection = true
  config.dashboard = false
  config.generate_docs = true
end
```

---

## Introspection & Documentation

Facera provides powerful introspection capabilities:

### Introspection API

```bash
# Full introspection
GET /api/facera/introspect

# Inspect cores
GET /api/facera/cores
GET /api/facera/cores/:name

# Inspect facets
GET /api/facera/facets
GET /api/facera/facets/:name

# Mounted configuration
GET /api/facera/mounted
```

### OpenAPI Generation

Automatically generate OpenAPI 3.0 specs:

```bash
# Get OpenAPI spec for specific facet
GET /api/facera/openapi/external

# Get all facets' OpenAPI specs
GET /api/facera/openapi
```

**Example response:**

```json
{
  "openapi": "3.0.3",
  "info": {
    "title": "External API",
    "description": "Public API for external clients",
    "version": "0.1.0"
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
        "responses": {
          "200": {
            "description": "Service is healthy"
          }
        }
      }
    },
    "/payments": {
      "post": {
        "summary": "Create a new payment",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": {
                  "amount": { "type": "number" },
                  "currency": { "type": "string" }
                },
                "required": ["amount", "currency"]
              }
            }
          }
        }
      }
    }
  }
}
```

### Programmatic Introspection

```ruby
# Introspect programmatically
require 'facera'

# Get all cores
cores = Facera::Introspection.inspect_cores

# Get specific facet
facet = Facera::Introspection.inspect_facet(:external)

# Generate OpenAPI spec
openapi = Facera::OpenAPIGenerator.for_facet(:external)
```

---

## Examples

Facera includes comprehensive examples:

### Phase Examples

Located in `examples/`:

- **01_core_dsl.rb** - Core definition with entities and capabilities
- **02_facet_system.rb** - Multiple facets from one core
- **03_api_generation.rb** - Auto-generated REST APIs
- **04_auto_mounting.rb** - Zero-config auto-mounting

Run them:

```bash
cd examples
ruby 01_core_dsl.rb
ruby 02_facet_system.rb
ruby 03_api_generation.rb
ruby 04_auto_mounting.rb
```

### Runnable Server

Located in `examples/server/`:

```bash
cd examples/server
rackup -p 9292
```

Test the APIs:

```bash
# Health checks
curl http://localhost:9292/api/v1/health
curl http://localhost:9292/api/internal/v1/health
curl http://localhost:9292/api/operator/v1/health

# Create payment
curl -X POST http://localhost:9292/api/v1/payments \
  -H 'Content-Type: application/json' \
  -d '{
    "amount": 100.0,
    "currency": "USD",
    "merchant_id": "550e8400-e29b-41d4-a716-446655440000",
    "customer_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
  }'

# Introspection
curl http://localhost:9292/api/facera/introspect | jq .
curl http://localhost:9292/api/facera/openapi/external | jq .
```

---

## Deployment

Facera is a standard Rack application and works with all Ruby web servers:

### Puma (Recommended)

```ruby
# config/puma.rb
workers ENV.fetch('WEB_CONCURRENCY', 2)
threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
threads threads_count, threads_count

port ENV.fetch('PORT', 9292)
environment ENV.fetch('RACK_ENV', 'development')

preload_app!
```

```bash
puma -C config/puma.rb
```

### Unicorn

```ruby
# config/unicorn.rb
worker_processes 4
listen 9292
timeout 30
preload_app true
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

```bash
docker build -t facera-app .
docker run -p 9292:9292 facera-app
```

### Environment Variables

```bash
# Required
DATABASE_URL=postgresql://...
REDIS_URL=redis://...

# Optional
ENABLE_OPERATOR_API=true
RACK_ENV=production
PORT=9292
```

---

## Architecture

### Design Principles

1. **Single Source of Truth**: Define your domain once in the core
2. **Facet-Oriented**: Multiple projections from one semantic model
3. **Convention Over Configuration**: Auto-discovery eliminates boilerplate
4. **Zero Duplication**: APIs are generated, not written
5. **Consistency by Design**: All facets share the same core logic

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                         Your Code                            │
├─────────────────────────────────────────────────────────────┤
│  cores/                  facets/                            │
│  ├── payment_core.rb     ├── external_facet.rb              │
│  └── user_core.rb        ├── internal_facet.rb              │
│                          └── operator_facet.rb              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                      Facera Framework                        │
├─────────────────────────────────────────────────────────────┤
│  Auto-Discovery → Loader → Registry → API Generator         │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                    Generated REST APIs                       │
├─────────────────────────────────────────────────────────────┤
│  /api/v1              - External API (limited access)       │
│  /api/internal/v1     - Internal API (full access)          │
│  /api/operator/v1     - Operator API (admin features)       │
│  /api/facera          - Introspection & OpenAPI             │
└─────────────────────────────────────────────────────────────┘
```

### Framework Integration

**Rails**
```ruby
# Gemfile
gem 'facera'

# config/application.rb
require 'facera'

# Facera automatically integrates via Railtie
# Cores and facets in app/cores/ and app/facets/ are auto-loaded
```

**Sinatra**
```ruby
require 'sinatra'
require 'facera'

Facera.auto_mount!(Sinatra::Application)

run Sinatra::Application
```

**Pure Rack**
```ruby
require 'facera'

run Rack::Builder.new {
  Facera.auto_mount!(self)
}
```

---

## Testing

Facera includes a comprehensive test suite:

```bash
bundle exec rspec
```

**Test your facets:**

```ruby
require 'spec_helper'

RSpec.describe "External Facet" do
  let(:api) { Facera.api_for(:external) }

  it "creates payment" do
    post '/payments', {
      amount: 100.0,
      currency: 'USD',
      merchant_id: '550e8400-e29b-41d4-a716-446655440000',
      customer_id: '6ba7b810-9dad-11d1-80b4-00c04fd430c8'
    }

    expect(last_response.status).to eq(201)
    expect(json_response).to include('id', 'amount', 'currency')
    expect(json_response).not_to include('merchant_id')  # Hidden in external
  end
end
```

---

## Contributing

We welcome contributions! Here's how to help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests
5. Run the test suite (`bundle exec rspec`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Development Setup

```bash
git clone https://github.com/yourusername/facera.git
cd facera
bundle install
bundle exec rspec
```

---

## Roadmap

- [x] Core DSL (entities, capabilities, invariants)
- [x] Facet system (field visibility, capability access)
- [x] API generation (auto-generated REST APIs)
- [x] Auto-mounting (zero-config discovery)
- [x] Introspection API
- [x] OpenAPI generation
- [ ] Dashboard UI (Sinatra-based visualization)
- [ ] Code generators (TypeScript/Ruby clients)
- [ ] GraphQL support
- [ ] WebSocket support
- [ ] Versioning strategies
- [ ] Advanced middleware (caching, logging, metrics)

---

## License

MIT License - see [LICENSE](LICENSE) for details

---

## Credits

Created by [Juan Carlos Garcia](https://github.com/jcagarcia)

Inspired by the need for consistent multi-audience APIs.

---

## Support

- 📚 [Documentation](https://github.com/yourusername/facera/wiki)
- 💬 [Discussions](https://github.com/yourusername/facera/discussions)
- 🐛 [Issues](https://github.com/yourusername/facera/issues)

---

**One semantic core. Multiple API facets. Zero duplication.**

Start building better APIs today with Facera! 💎
