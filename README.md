# Facera

**One semantic core. Multiple API facets. Zero duplication.**

Facera is a Ruby framework for building **multi-facet APIs** from a single semantic core. Define your domain model once, then expose different views for different consumers—all guaranteed consistent by design.

<img src="img/facera.png" alt="Facera logo" width="250"/>

[![Gem Version](https://badge.fury.io/rb/facera.svg)](https://badge.fury.io/rb/facera)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## Why Facera?

Modern systems expose APIs to many different consumers, leading to duplicated endpoints, inconsistent representations, and maintenance burden. **Facera solves this** by letting you define your system **once** as a semantic core, then automatically generate multiple consistent API facets.

### Before Facera
```
3 separate APIs × 5 endpoints = 15 implementations
+ 3 serializers + 3 auth systems + 3 test suites
= ~2000 lines of code
```

### With Facera
```
1 core definition + 3 facet files + 1 config
= ~300 lines of code
```

**85% less code, 100% consistency guaranteed.**

---

## Quick Start

### Installation

```bash
gem install facera
```

Or add to your Gemfile:

```ruby
gem 'facera'
```

### 1. Define Your Core

```ruby
# cores/payment_core.rb
Facera.define_core(:payment) do
  entity :payment do
    attribute :id, :uuid, immutable: true
    attribute :amount, :money, required: true
    attribute :currency, :string, required: true
    attribute :status, :enum, values: [:pending, :confirmed, :cancelled]
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
end
```

### 2. Define Facets

```ruby
# facets/external_facet.rb
Facera.define_facet(:external, core: :payment) do
  description "Public API for external clients"

  expose :payment do
    fields :id, :amount, :currency, :status
  end

  allow_capabilities :create_payment
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

**That's it!** You now have multiple APIs auto-generated:

```bash
# External API (limited fields)
curl http://localhost:9292/api/v1/health
curl -X POST http://localhost:9292/api/v1/payments \
  -H 'Content-Type: application/json' \
  -d '{"amount": 100.0, "currency": "USD", ...}'

# Internal API (all fields + computed)
curl http://localhost:9292/api/internal/v1/payments/:id

# Introspection
curl http://localhost:9292/api/facera/introspect
curl http://localhost:9292/api/facera/openapi/external
```

---

## Key Features

- 💎 **Single Source of Truth** - Define domain model once
- 🎭 **Multiple Facets** - Different views for different consumers
- 🚀 **Auto-Generated APIs** - REST endpoints created automatically
- 📦 **Zero Configuration** - Convention-based auto-discovery
- 📚 **Built-in Introspection** - Explore your APIs at runtime
- 📄 **OpenAPI Generation** - Auto-generated API documentation
- 🔒 **Type Safety** - Strong typing for entities and capabilities
- ✅ **Business Rules** - Invariants and validations in the core

---

## Documentation

Comprehensive documentation available in the [wiki](https://github.com/jcagarcia/facera/wiki):

- **[Core Concepts](https://github.com/jcagarcia/facera/wiki/Core-Concepts)** - Understanding cores, facets, and projections
- **[Defining Cores](https://github.com/jcagarcia/facera/wiki/Defining-Cores)** - Entities, capabilities, and invariants
- **[Defining Facets](https://github.com/jcagarcia/facera/wiki/Defining-Facets)** - Field visibility and capability access
- **[API Generation](https://github.com/jcagarcia/facera/wiki/API-Generation)** - Auto-generated REST endpoints
- **[Auto-Mounting](https://github.com/jcagarcia/facera/wiki/Auto-Mounting)** - Convention-based discovery
- **[Configuration](https://github.com/jcagarcia/facera/wiki/Configuration)** - Authentication, paths, and feature flags
- **[Introspection](https://github.com/jcagarcia/facera/wiki/Introspection)** - Runtime introspection and OpenAPI
- **[Deployment](https://github.com/jcagarcia/facera/wiki/Deployment)** - Production deployment guides
- **[Architecture](https://github.com/jcagarcia/facera/wiki/Architecture)** - Design principles and framework integration
- **[Examples](https://github.com/jcagarcia/facera/wiki/Examples)** - Complete working examples

---

## Example Structure

```
your_app/
├── cores/
│   └── payment_core.rb       # Domain model
├── facets/
│   ├── external_facet.rb     # Public API
│   ├── internal_facet.rb     # Service API
│   └── operator_facet.rb     # Admin API
└── config.ru                 # Rack config
```

Facera auto-discovers everything and generates:

```
GET  /api/v1/health
POST /api/v1/payments
GET  /api/v1/payments/:id

GET  /api/internal/v1/health
POST /api/internal/v1/payments
GET  /api/internal/v1/payments/:id
POST /api/internal/v1/payments/:id/confirm

GET  /api/facera/introspect
GET  /api/facera/cores
GET  /api/facera/facets
GET  /api/facera/openapi
```

---

## Examples

See the [examples/](examples/) directory for complete working examples:

- **Phase Examples** - `01_core_dsl.rb` through `04_auto_mounting.rb`
- **Runnable Server** - `examples/server/` with multiple facets

Run the server:

```bash
cd examples/server
rackup -p 9292
```

---

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](https://github.com/jcagarcia/facera/wiki/Contributing) for guidelines.

```bash
git clone https://github.com/yourusername/facera.git
cd facera
bundle install
bundle exec rspec
```

---

## License

MIT License - see [LICENSE](LICENSE) for details

---

## Credits

Created by [Juan Carlos Garcia](https://github.com/jcagarcia)

---

**One semantic core. Multiple API facets. Zero duplication.**

Start building better APIs today! 💎
