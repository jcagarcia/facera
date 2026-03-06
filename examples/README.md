# Facera Examples

This directory contains examples demonstrating Facera's capabilities, organized by implementation phase.

## Overview

Each example builds on the previous one, showing the progressive development of a multi-facet payment API:

```
01_core_dsl.rb         → Phase 1: Core semantic definition
02_facet_system.rb     → Phase 2: Multiple facets from one core
03_api_generation.rb   → Phase 3: Auto-generated REST APIs
server/                → Runnable HTTP server
```

## Running the Examples

### Phase 1: Core DSL

Demonstrates the basic building blocks: entities, capabilities, and invariants.

```bash
ruby 01_core_dsl.rb
```

**Shows:**
- Entity definition with typed attributes
- Capability definitions (create, get, list, actions)
- Business invariants
- Parameter requirements and validations

### Phase 2: Facet System

Shows how multiple facets can be created from a single core, each with different visibility and access rules.

```bash
ruby 02_facet_system.rb
```

**Shows:**
- 4 different facets (external, internal, operator, agent)
- Field visibility control per facet
- Capability access control
- Computed fields
- Feature comparison matrix

### Phase 3: API Generation

Demonstrates automatic REST API generation using Grape.

```bash
ruby 03_api_generation.rb
```

**Shows:**
- Auto-generated REST endpoints
- Field serialization based on facet rules
- Capability-to-endpoint mapping
- Route comparison across facets

### Running the Server

Launch a live HTTP server with multiple facet APIs:

```bash
cd server
rackup -p 9292
```

Then test the APIs:

```bash
# Check health
curl http://localhost:9292/external/health

# List payments (external API)
curl http://localhost:9292/external/payments

# Create a payment
curl -X POST http://localhost:9292/external/payments \
  -H 'Content-Type: application/json' \
  -d '{
    "amount": 100.0,
    "currency": "USD",
    "merchant_id": "550e8400-e29b-41d4-a716-446655440000",
    "customer_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
  }'

# Confirm payment (internal API only - not available in external)
curl -X POST http://localhost:9292/internal/payments/{id}/confirm
```

## Server Structure

```
server/
├── config.ru        # Rack configuration (mounts APIs)
└── payment_api.rb   # Shared DSL definitions (core + facets)
```

**Why separate?**
- `payment_api.rb` contains reusable DSL definitions
- `config.ru` handles HTTP routing and server configuration
- Clean separation of concerns
- Easy to test definitions independently

## Key Concepts Demonstrated

### 1. Single Source of Truth
Define your domain model once in the core:
```ruby
Facera.define_core(:payment) do
  entity :payment do
    attribute :amount, :money, required: true
  end
end
```

### 2. Multiple Projections
Create different views for different consumers:
```ruby
Facera.define_facet(:external, core: :payment) do
  expose :payment do
    fields :id, :amount  # Limited fields
  end
  allow_capabilities :create_payment  # Limited access
end

Facera.define_facet(:internal, core: :payment) do
  expose :payment do
    fields :all  # Full visibility
  end
  allow_capabilities :all  # Full access
end
```

### 3. Zero Boilerplate APIs
Generate complete REST APIs automatically:
```ruby
api = Facera.api_for(:external)
# Auto-generates: POST /payments, GET /payments/:id, etc.
```

## Next Steps

After running these examples:
1. Explore the generated routes in `03_api_generation.rb`
2. Test the live server in `server/`
3. Modify `server/payment_api.rb` to add your own facets
4. Check the test suite in `spec/` for more examples

## Tips

- **Start simple**: Run examples in order (01 → 02 → 03 → server)
- **Experiment**: Modify `server/payment_api.rb` and restart the server
- **Compare facets**: Notice how external vs. internal APIs differ
- **Check visibility**: See how field exposure changes per facet
