# Examples

Complete working examples to get you started.

---

## Quick Examples

Located in `examples/` directory.

### 01_core_dsl.rb

Basic core definition with entities and capabilities:

```ruby
require_relative '../lib/facera'

# Define a simple payment core
Facera.define_core(:payment) do
  entity :payment do
    attribute :id, :uuid, immutable: true
    attribute :amount, :money, required: true
    attribute :currency, :string, required: true
    attribute :status, :enum, values: [:pending, :confirmed, :cancelled]
  end

  capability :create_payment, type: :create do
    entity :payment
    requires :amount, :currency
    validates { amount > 0 }
  end

  capability :confirm_payment, type: :action do
    entity :payment
    requires :id
    precondition { status == :pending }
    transitions_to :confirmed
  end

  invariant :positive_amount do
    amount > 0
  end
end

# Inspect what we defined
core = Facera::Registry.cores[:payment]
puts "Core: #{core.name}"
puts "Entities: #{core.entities.keys}"
puts "Capabilities: #{core.capabilities.keys}"
```

**Run:**
```bash
ruby examples/01_core_dsl.rb
```

### 02_facet_system.rb

Multiple facets from one core:

```ruby
require_relative '../lib/facera'
require_relative '01_core_dsl'

# External facet (public API)
Facera.define_facet(:external, core: :payment) do
  description "Public API for external clients"

  expose :payment do
    fields :id, :amount, :currency, :status
  end

  allow_capabilities :create_payment, :get_payment
  error_verbosity :minimal
end

# Internal facet (service API)
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
end

# Operator facet (admin API)
Facera.define_facet(:operator, core: :payment) do
  description "Admin API for operators"

  expose :payment do
    fields :all
    computed :audit_trail do |payment|
      "Audit data for #{payment.id}"
    end
  end

  allow_capabilities :all
  error_verbosity :structured
  audit_all_operations user: :admin_user
end

# Inspect facets
Facera::Registry.facets.each do |name, facet|
  puts "\nFacet: #{name}"
  puts "  Core: #{facet.core_name}"
  puts "  Capabilities: #{facet.allowed_capabilities.count}"
  puts "  Fields: #{facet.field_visibilities.values.first.visible_fields.count}"
end
```

**Run:**
```bash
ruby examples/02_facet_system.rb
```

### 03_api_generation.rb

Auto-generated REST APIs:

```ruby
require_relative '../lib/facera'
require_relative '../cores/payment_core'
require_relative '../facets/external_facet'

# Generate API for facet
api = Facera::Grape::APIGenerator.for_facet(:external)

puts "Generated API:"
puts "  Routes: #{api.routes.count}"

api.routes.each do |route|
  puts "  #{route.request_method} #{route.path}"
end

# Generate OpenAPI spec
openapi = Facera::OpenAPIGenerator.for_facet(:external)

puts "\nOpenAPI Spec:"
puts "  Title: #{openapi[:info][:title]}"
puts "  Paths: #{openapi[:paths].keys.join(', ')}"
```

**Run:**
```bash
ruby examples/03_api_generation.rb
```

### 04_auto_mounting.rb

Zero-config auto-mounting:

```ruby
require_relative '../lib/facera'

# Configure
Facera.configure do |config|
  config.base_path = '/api'
  config.version = 'v1'
end

# Auto-mount (discovers cores/ and facets/ automatically)
app = Rack::Builder.new do
  Facera.auto_mount!(self)
end

# Show what was mounted
puts "\nMounted facets:"
Facera::Registry.facets.each do |name, facet|
  path = Facera.configuration.path_for_facet(name)
  puts "  #{name.to_s.ljust(15)} -> #{path}"
end
```

**Run:**
```bash
ruby examples/04_auto_mounting.rb
```

---

## Runnable Server

Complete working server in `examples/server/`.

### File Structure

```
examples/server/
├── cores/
│   └── payment_core.rb
├── facets/
│   ├── external_facet.rb
│   ├── internal_facet.rb
│   └── operator_facet.rb
├── config/
│   └── facera.rb
├── application.rb
└── config.ru
```

### cores/payment_core.rb

```ruby
Facera.define_core(:payment) do
  entity :payment do
    attribute :id, :uuid, immutable: true
    attribute :amount, :money, required: true
    attribute :currency, :string, required: true
    attribute :status, :enum,
      values: [:pending, :confirmed, :cancelled, :refunded],
      required: true
    attribute :merchant_id, :uuid, required: true
    attribute :customer_id, :uuid, required: true
    attribute :created_at, :datetime
    attribute :confirmed_at, :datetime
  end

  capability :create_payment, type: :create do
    entity :payment
    requires :amount, :currency, :merchant_id, :customer_id
    validates { amount > 0 }
    sets created_at: -> { Time.now }
    sets status: :pending
  end

  capability :get_payment, type: :get do
    entity :payment
    requires :id
  end

  capability :list_payments, type: :list do
    entity :payment
    filterable :merchant_id, :customer_id, :status
  end

  capability :confirm_payment, type: :action do
    entity :payment
    requires :id
    precondition { status == :pending }
    transitions_to :confirmed
    sets confirmed_at: -> { Time.now }
  end

  invariant :positive_amount do
    amount > 0
  end
end
```

### facets/external_facet.rb

```ruby
Facera.define_facet(:external, core: :payment) do
  description "Public API for external clients"

  expose :payment do
    fields :id, :amount, :currency, :status
  end

  allow_capabilities :create_payment, :get_payment, :list_payments
  error_verbosity :minimal
end
```

### facets/internal_facet.rb

```ruby
Facera.define_facet(:internal, core: :payment) do
  description "Service-to-service API"

  expose :payment do
    fields :all
    computed :processing_time do |payment|
      payment.created_at ? (Time.now - payment.created_at).to_i : 0
    end
  end

  allow_capabilities :all
  error_verbosity :detailed
end
```

### facets/operator_facet.rb

```ruby
Facera.define_facet(:operator, core: :payment) do
  description "Admin API for operators"

  expose :payment do
    fields :all
    computed :audit_info do |payment|
      {
        created: payment.created_at,
        confirmed: payment.confirmed_at,
        current_status: payment.status
      }
    end
  end

  allow_capabilities :all
  error_verbosity :detailed
end
```

### config/facera.rb

```ruby
Facera.configure do |config|
  config.base_path = '/api'
  config.version = 'v1'

  config.facet_path :external, '/v1'
  config.facet_path :internal, '/internal/v1'
  config.facet_path :operator, '/operator/v1'

  config.introspection = true
  config.dashboard = false
  config.generate_docs = true
end
```

### application.rb

```ruby
module PaymentAPI
  class Application
    def self.build
      Rack::Builder.new do
        use Rack::Reloader, 0 if ENV['RACK_ENV'] == 'development'
        use Rack::CommonLogger

        Facera.auto_mount!(self)
      end
    end
  end
end
```

### config.ru

```ruby
require_relative '../../lib/facera'
require_relative 'config/facera'
require_relative 'application'

run PaymentAPI::Application.build
```

### Run the Server

```bash
cd examples/server
rackup -p 9292
```

You'll see:
```
================================================================================
💎 Facera v0.1.0 - Auto-Mounting
================================================================================
📦 Loading cores...
  ✓ payment_core
🎭 Loading facets...
  ✓ external_facet
  ✓ internal_facet
  ✓ operator_facet

📊 Found:
  Cores: 1
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

### Test the APIs

**Health checks:**
```bash
curl http://localhost:9292/api/v1/health
curl http://localhost:9292/api/internal/v1/health
curl http://localhost:9292/api/operator/v1/health
```

**Create payment (external):**
```bash
curl -X POST http://localhost:9292/api/v1/payments \
  -H 'Content-Type: application/json' \
  -d '{
    "amount": 100.0,
    "currency": "USD",
    "merchant_id": "550e8400-e29b-41d4-a716-446655440000",
    "customer_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
  }'
```

**Response:**
```json
{
  "id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
  "amount": 100.0,
  "currency": "USD",
  "status": "pending"
}
```

**Get payment (internal - shows all fields):**
```bash
curl http://localhost:9292/api/internal/v1/payments/7c9e6679-7425-40de-944b-e07fc1f90ae7
```

**Confirm payment (internal only):**
```bash
curl -X POST http://localhost:9292/api/internal/v1/payments/7c9e6679-7425-40de-944b-e07fc1f90ae7/confirm
```

**Try to confirm via external (not allowed):**
```bash
curl -X POST http://localhost:9292/api/v1/payments/7c9e6679-7425-40de-944b-e07fc1f90ae7/confirm
# 404 Not Found
```

**Introspection:**
```bash
curl http://localhost:9292/api/facera/introspect | jq .
curl http://localhost:9292/api/facera/cores | jq .
curl http://localhost:9292/api/facera/facets | jq .
curl http://localhost:9292/api/facera/openapi/external | jq .
```

---

## Testing Examples

### RSpec Tests

```ruby
# spec/facets/external_spec.rb
require 'spec_helper'

RSpec.describe "External Facet" do
  include Rack::Test::Methods

  def app
    PaymentAPI::Application.build
  end

  describe "POST /api/v1/payments" do
    it "creates a payment" do
      post '/api/v1/payments', {
        amount: 100.0,
        currency: 'USD',
        merchant_id: '550e8400-e29b-41d4-a716-446655440000',
        customer_id: '6ba7b810-9dad-11d1-80b4-00c04fd430c8'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(201)
      json = JSON.parse(last_response.body)
      expect(json).to include('id', 'amount', 'currency', 'status')
      expect(json['amount']).to eq(100.0)
    end

    it "validates amount is positive" do
      post '/api/v1/payments', {
        amount: -100.0,
        currency: 'USD',
        merchant_id: '550e8400-e29b-41d4-a716-446655440000',
        customer_id: '6ba7b810-9dad-11d1-80b4-00c04fd430c8'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(400)
    end
  end

  describe "GET /api/v1/payments/:id" do
    it "returns payment with limited fields" do
      # Create payment first
      post '/api/v1/payments', {...}.to_json

      id = JSON.parse(last_response.body)['id']

      get "/api/v1/payments/#{id}"

      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body)
      expect(json).to include('id', 'amount', 'currency', 'status')
      expect(json).not_to include('merchant_id')  # Hidden in external
    end
  end

  describe "POST /api/v1/payments/:id/confirm" do
    it "is not available in external facet" do
      post '/api/v1/payments', {...}.to_json
      id = JSON.parse(last_response.body)['id']

      post "/api/v1/payments/#{id}/confirm"

      expect(last_response.status).to eq(404)
    end
  end
end
```

---

## Next Steps

- [Deployment](Deployment.md) - Deploy to production
- [Architecture](Architecture.md) - Understand how it works
- [Contributing](Contributing.md) - Contribute to Facera
