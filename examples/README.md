# Facera Examples

This directory contains examples demonstrating Facera's capabilities, organized by implementation phase.

## Overview

Each example builds on the previous one, showing the progressive development of a multi-facet payment API:

```
01_core_dsl.rb         → Phase 1: Core semantic definition
02_facet_system.rb     → Phase 2: Multiple facets from one core
03_api_generation.rb   → Phase 3: Auto-generated REST APIs
04_auto_mounting.rb    → Phase 4: Auto-mounting system
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

### Phase 4: Auto-Mounting

Shows how Facera automatically discovers and mounts all facets with zero configuration.

```bash
ruby 04_auto_mounting.rb
```

**Shows:**
- Zero-config auto-mounting
- Custom path configuration
- Facet enabling/disabling
- Rails integration (Railtie)
- Rack/Sinatra integration
- Per-facet authentication
- Configuration DSL

### Running the Server

Launch a live HTTP server with multiple facet APIs:

```bash
cd server
rackup -p 9292
```

Then test the APIs:

```bash
# Check health
curl http://localhost:9292/public/api/v1/health

# List payments (public API)
curl http://localhost:9292/public/api/v1/payments

# Create a payment
curl -X POST http://localhost:9292/public/api/v1/payments \
  -H 'Content-Type: application/json' \
  -d '{
    "amount": 100.0,
    "currency": "USD",
    "merchant_id": "550e8400-e29b-41d4-a716-446655440000",
    "customer_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
  }'

# Confirm payment (internal API only)
curl -X POST http://localhost:9292/internal/api/v1/payments/{id}/confirm
```

## Server Structure

```
server/
├── config.ru            # Rack server (just 38 lines!)
├── config/
│   └── facera.rb       # Facera configuration
├── cores/
│   └── payment_core.rb # Domain model
└── facets/
    ├── external_facet.rb
    ├── internal_facet.rb
    └── operator_facet.rb
```

**Convention over configuration:**
- `config.ru` - Just loads config and calls `Facera.auto_mount!`
- `config/facera.rb` - All configuration in one place
- `cores/` - Drop files here, auto-discovered!
- `facets/` - Drop files here, auto-discovered!
- **No manual requires needed** - Facera finds everything automatically
- Zero boilerplate

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
