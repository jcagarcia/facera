# Core Concepts

Understanding the fundamental concepts behind Facera's architecture.

---

## The Facet Model

```
            Facet: external (limited fields, public)
                  │
Facet: agent ── Core ── Facet: internal (all fields, full access)
                  │
            Facet: operator (admin fields, audit logs)
```

The **core** defines the semantic meaning of your system. **Facets** project that meaning appropriately for different consumers.

---

## Core

The single source of truth for your domain model. Defines:

- **Entities**: Domain objects (payments, users, orders)
- **Capabilities**: Actions that can be performed
- **Invariants**: Business rules that must always hold
- **Transitions**: Valid state changes

### Example Core

```ruby
Facera.define_core(:payment) do
  entity :payment do
    attribute :id, :uuid, immutable: true
    attribute :amount, :money, required: true
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
```

---

## Facet

A consumer-specific projection that controls:

- **Field visibility**: Which entity fields are exposed
- **Capability access**: Which actions are available
- **Computed fields**: Additional derived data
- **Error verbosity**: How much detail to include in errors
- **Audit logging**: Whether to log operations

### Example Facets

**External (Public API)**
```ruby
Facera.define_facet(:external, core: :payment) do
  expose :payment do
    fields :id, :amount, :currency, :status
  end

  allow_capabilities :create_payment
  error_verbosity :minimal
end
```

**Internal (Service API)**
```ruby
Facera.define_facet(:internal, core: :payment) do
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

**Operator (Admin API)**
```ruby
Facera.define_facet(:operator, core: :payment) do
  expose :payment do
    fields :all
    computed :audit_trail do |payment|
      PaymentAudit.for(payment.id)
    end
  end

  allow_capabilities :all
  error_verbosity :detailed
  audit_all_operations user: :admin_user, ip: :remote_ip
end
```

---

## Why This Architecture?

### Single Source of Truth

Define business logic once in the core:
- Validation rules
- State transitions
- Business invariants
- Domain constraints

All facets inherit this logic automatically.

### Consistency Guaranteed

Since all facets derive from the same core:
- No duplicate logic
- No inconsistent behavior
- Changes propagate automatically
- Testing is centralized

### Consumer-Specific Views

Each facet exposes only what its consumer needs:
- External clients see minimal data
- Internal services see everything
- Operators get audit information
- Agents get machine-readable formats

### Zero Duplication

```
Without Facera:
├── external_api/
│   ├── payments_controller.rb
│   ├── payments_serializer.rb
│   ├── payments_validator.rb
│   └── payments_spec.rb
├── internal_api/
│   ├── payments_controller.rb
│   ├── payments_serializer.rb
│   ├── payments_validator.rb
│   └── payments_spec.rb
└── operator_api/
    ├── payments_controller.rb
    ├── payments_serializer.rb
    ├── payments_validator.rb
    └── payments_spec.rb

With Facera:
├── cores/
│   └── payment_core.rb
└── facets/
    ├── external_facet.rb
    ├── internal_facet.rb
    └── operator_facet.rb
```

**3 implementations → 1 core + 3 configurations**

---

## Design Principles

1. **Single Source of Truth**: One core, many projections
2. **Facet-Oriented**: Different views for different consumers
3. **Convention Over Configuration**: Auto-discovery eliminates boilerplate
4. **Zero Duplication**: APIs are generated, not written
5. **Consistency by Design**: All facets share core logic

---

## Next Steps

- [Defining Cores](Defining-Cores.md) - Learn how to define entities and capabilities
- [Defining Facets](Defining-Facets.md) - Learn how to create consumer-specific views
- [API Generation](API-Generation.md) - Understand how REST APIs are generated
