# Facera

**One semantic core. Multiple API facets. Zero duplication.**

Facera is a Ruby framework for building **multi-facet APIs** from a single semantic core. Define your domain model once, then expose different views for different consumers—all guaranteed consistent by design.

<img src="img/facera.png" alt="Facera logo" width="250"/>

[![Gem Version](https://badge.fury.io/rb/facera.svg)](https://badge.fury.io/rb/facera)
[![Ruby CI](https://github.com/jcagarcia/facera/actions/workflows/ruby.yml/badge.svg)](https://github.com/jcagarcia/facera/actions/workflows/ruby.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## Why Facera?

Modern systems expose APIs to many different consumers, leading to duplicated endpoints, inconsistent representations, and maintenance burden. **Facera solves this** by letting you define your system **once** as a semantic core, then automatically generate multiple consistent API facets.

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

All audience facets for a core live in a single file named after the core:

```ruby
# facets/payment_facets.rb
# Facet name = audience name only. The core is declared via core:.
# Same audience name across cores → grouped into one API at /{audience}/{version}.

Facera.define_facet(:public, core: :payment) do
  description "Customer-facing payments API"

  expose :payment do
    fields :id, :amount, :currency, :status
  end

  allow_capabilities :create_payment, :get_payment
  error_verbosity :minimal
  rate_limit requests: 1000, per: :hour
end

Facera.define_facet(:internal, core: :payment) do
  description "Internal service-to-service payments API"

  expose :payment do
    fields :all
    computed :age_in_seconds do
      created_at ? (Time.now - created_at).to_i : 0
    end
  end

  allow_capabilities :all
  error_verbosity :detailed
end

Facera.define_facet(:ops, core: :payment) do
  description "Operator and support agent payments API"

  expose :payment do
    fields :all
    computed :customer_display do
      "Customer #{customer_id[0..7]}"
    end
  end

  allow_capabilities :all
  error_verbosity :detailed
  audit_all_operations user: :current_agent
end
```

Name facets after the business audience consuming them. Facets sharing the same audience name across cores are automatically merged into one API — no configuration required.

### 3. Implement Business Logic

Create an adapter to implement the actual logic:

```ruby
# adapters/payment_adapter.rb
class PaymentAdapter
  include Facera::Adapter

  def create_payment(params)
    # Your business logic here
    Payment.create!(
      amount: params[:amount],
      currency: params[:currency],
      merchant_id: params[:merchant_id],
      customer_id: params[:customer_id],
      status: :pending
    )
  end

  def get_payment(params)
    Payment.find(params[:id])
  end

  def confirm_payment(params)
    payment = Payment.find(params[:id])
    payment.update!(status: :confirmed, confirmed_at: Time.now)
    payment
  end
end
```

### 4. Mount and Run

```ruby
# config.ru
require 'facera'

app = Rack::Builder.new do
  Facera.auto_mount!(self)
end

run app
```

Start your server:

```bash
rackup -p 9292
```

**That's it!** Facera auto-discovers everything and generates:

```bash
# Public API (customer-facing) — /payments and /refunds
curl http://localhost:9292/public/api/v1/payments
curl -X POST http://localhost:9292/public/api/v1/payments \
  -H 'Content-Type: application/json' \
  -d '{"amount": 100.0, "currency": "USD", ...}'

# Internal API (service-to-service) — /payments and /refunds
curl http://localhost:9292/internal/api/v1/payments/:id

# Ops API (operators and support agents) — /payments and /refunds
curl http://localhost:9292/ops/api/v1/payments/:id

# Introspection
curl http://localhost:9292/facera/introspect
curl http://localhost:9292/facera/openapi/public
```

---

## File Structure Convention

The key insight: **one facets file per core**, containing all audience variants.

```
your_app/
├── cores/
│   ├── payment_core.rb           # Payment domain model
│   └── refund_core.rb            # Refund domain model
├── adapters/
│   ├── payment_adapter.rb        # Payment business logic
│   └── refund_adapter.rb         # Refund business logic
├── facets/
│   ├── payment_facets.rb         # public, internal, ops  (core: :payment)
│   └── refund_facets.rb          # public, internal, ops   (core: :refund)
└── config.ru
```

Facera auto-discovers everything by convention — no manual registration needed.

---

## Default Path Convention

Facet paths are derived automatically from the audience name. Facets sharing the same audience name across cores are grouped into one mounted API:

| Audience name   | Cores included    | Default path              | Resources              |
|-----------------|-------------------|---------------------------|------------------------|
| `public`    | payment + refund | `/public/api/v1`      | `/payments`, `/refunds` |
| `internal`  | payment + refund | `/internal/api/v1`    | `/payments`, `/refunds` |
| `ops`       | payment + refund | `/ops/api/v1`         | `/payments`, `/refunds` |

You can override any audience path explicitly if needed:

```ruby
Facera.configure do |config|
  config.facet_path :public, '/public/api/v2'  # custom override
end
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
- **[Implementing Business Logic](https://github.com/jcagarcia/facera/wiki/Implementing-Business-Logic)** - Adapters and execute blocks
- **[API Generation](https://github.com/jcagarcia/facera/wiki/API-Generation)** - Auto-generated REST endpoints
- **[Auto-Mounting](https://github.com/jcagarcia/facera/wiki/Auto-Mounting)** - Convention-based discovery
- **[Configuration](https://github.com/jcagarcia/facera/wiki/Configuration)** - Authentication, paths, and feature flags
- **[Introspection](https://github.com/jcagarcia/facera/wiki/Introspection)** - Runtime introspection and OpenAPI
- **[Deployment](https://github.com/jcagarcia/facera/wiki/Deployment)** - Production deployment guides
- **[Architecture](https://github.com/jcagarcia/facera/wiki/Architecture)** - Design principles and framework integration
- **[Examples](https://github.com/jcagarcia/facera/wiki/Examples)** - Complete working examples

---

## Examples

See the [examples/](examples/) directory for complete working examples:

- **Phase Examples** - `01_core_dsl.rb` through `04_auto_mounting.rb`
- **Runnable Server** - `examples/server/` with multiple cores and facets

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
