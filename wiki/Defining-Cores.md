# Defining Cores

Complete guide to defining semantic cores with entities, capabilities, and invariants.

---

## Basic Structure

```ruby
Facera.define_core(:core_name) do
  entity :entity_name do
    # attributes
  end

  capability :capability_name, type: :type do
    # capability definition
  end

  invariant :invariant_name do
    # business rule
  end
end
```

---

## Entities

Entities represent domain objects in your system.

### Attributes

Define entity attributes with types and constraints:

```ruby
entity :payment do
  # Basic types
  attribute :id, :uuid, immutable: true
  attribute :amount, :money, required: true
  attribute :description, :text

  # Enums with validation
  attribute :status, :enum,
    values: [:pending, :confirmed, :cancelled],
    required: true

  # Timestamps
  attribute :created_at, :datetime
  attribute :confirmed_at, :datetime

  # References
  attribute :merchant_id, :uuid, required: true
  attribute :customer_id, :uuid, required: true
end
```

### Supported Types

| Type | Description | Example |
|------|-------------|---------|
| `:string` | Short text | `"USD"` |
| `:text` | Long text | `"Payment description..."` |
| `:integer` | Whole number | `100` |
| `:float` | Decimal number | `99.99` |
| `:boolean` | True/false | `true` |
| `:uuid` | UUID string | `"550e8400-e29b-41d4..."` |
| `:money` | Decimal with precision | `100.50` |
| `:datetime` | Date and time | `2026-03-09T10:30:00Z` |
| `:date` | Date only | `2026-03-09` |
| `:enum` | One of specified values | `:pending` |
| `:hash` | JSON object | `{key: "value"}` |
| `:array` | JSON array | `[1, 2, 3]` |

### Attribute Options

- `required: true` - Must be provided
- `immutable: true` - Cannot be changed after creation
- `values: [...]` - Valid enum values
- `default: value` - Default value if not provided

---

## Capabilities

Capabilities define actions that can be performed on entities.

### Four Types

#### 1. Create

Create new entity instances:

```ruby
capability :create_payment, type: :create do
  entity :payment
  requires :amount, :currency, :merchant_id, :customer_id
  optional :description, :metadata

  validates do
    amount > 0 && currency.match?(/^[A-Z]{3}$/)
  end

  sets created_at: -> { Time.now }
  sets status: :pending
end
```

**Generated endpoint:**
```
POST /payments
```

#### 2. Get (Read Single)

Retrieve a single entity by ID:

```ruby
capability :get_payment, type: :get do
  entity :payment
  requires :id
end
```

**Generated endpoint:**
```
GET /payments/:id
```

#### 3. List (Read Multiple)

Retrieve multiple entities with filtering:

```ruby
capability :list_payments, type: :list do
  entity :payment
  optional :merchant_id, :customer_id, :status
  filterable :merchant_id, :customer_id, :status
  sortable :created_at, :amount
end
```

**Generated endpoint:**
```
GET /payments?merchant_id=...&status=pending
```

#### 4. Action (State Transitions)

Perform actions that change entity state:

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

**Generated endpoint:**
```
POST /payments/:id/confirm
```

### Capability Options

- `requires :field1, :field2` - Required parameters
- `optional :field3, :field4` - Optional parameters
- `validates { condition }` - Validation logic
- `precondition { condition }` - Pre-execution checks
- `transitions_to :state` - Target state after action
- `sets field: value` - Field values to set
- `filterable :field` - Allow filtering in lists
- `sortable :field` - Allow sorting in lists

---

## Invariants

Business rules that must always be true:

```ruby
invariant :positive_amount, "Amount must be positive" do
  amount > 0
end

invariant :valid_currency, "Currency must be 3-letter code" do
  currency.match?(/^[A-Z]{3}$/)
end

invariant :valid_transitions, "Only valid state transitions allowed" do
  case [old_status, new_status]
  when [:pending, :confirmed], [:pending, :cancelled]
    true
  else
    false
  end
end
```

Invariants are checked:
- Before creating entities
- After capability execution
- Before state transitions

---

## Complete Example

```ruby
Facera.define_core(:payment) do
  # Entity definition
  entity :payment do
    attribute :id, :uuid, immutable: true
    attribute :amount, :money, required: true
    attribute :currency, :string, required: true
    attribute :status, :enum,
      values: [:pending, :confirmed, :cancelled, :refunded],
      required: true
    attribute :merchant_id, :uuid, required: true
    attribute :customer_id, :uuid, required: true
    attribute :description, :text
    attribute :metadata, :hash
    attribute :created_at, :datetime
    attribute :confirmed_at, :datetime
    attribute :cancelled_at, :datetime
  end

  # Create capability
  capability :create_payment, type: :create do
    entity :payment
    requires :amount, :currency, :merchant_id, :customer_id
    optional :description, :metadata

    validates do
      amount > 0 &&
      currency.match?(/^[A-Z]{3}$/) &&
      merchant_id.match?(/^[0-9a-f-]{36}$/)
    end

    sets created_at: -> { Time.now }
    sets status: :pending
  end

  # Get capability
  capability :get_payment, type: :get do
    entity :payment
    requires :id
  end

  # List capability
  capability :list_payments, type: :list do
    entity :payment
    optional :merchant_id, :customer_id, :status
    filterable :merchant_id, :customer_id, :status
    sortable :created_at, :amount
  end

  # Confirm action
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

  # Cancel action
  capability :cancel_payment, type: :action do
    entity :payment
    requires :id
    optional :reason

    precondition do
      status == :pending
    end

    transitions_to :cancelled
    sets cancelled_at: -> { Time.now }
  end

  # Refund action
  capability :refund_payment, type: :action do
    entity :payment
    requires :id
    requires :refund_amount

    precondition do
      status == :confirmed &&
      refund_amount <= amount
    end

    transitions_to :refunded
  end

  # Invariants
  invariant :positive_amount, "Amount must be positive" do
    amount > 0
  end

  invariant :valid_currency, "Currency must be 3-letter ISO code" do
    currency.match?(/^[A-Z]{3}$/)
  end

  invariant :valid_transitions, "Only valid state transitions allowed" do
    valid_transition?(old_status, new_status)
  end

  invariant :confirmed_has_timestamp, "Confirmed payments must have timestamp" do
    status != :confirmed || confirmed_at.present?
  end
end
```

---

## Best Practices

### 1. Keep Cores Semantic

Focus on domain meaning, not implementation:

```ruby
# ✅ Good - semantic
capability :confirm_payment, type: :action do
  transitions_to :confirmed
end

# ❌ Bad - implementation detail
capability :set_payment_status_to_confirmed, type: :action do
  sets status: :confirmed
end
```

### 2. Use Invariants for Business Rules

```ruby
# ✅ Good - business rule in invariant
invariant :valid_refund do
  refund_amount <= original_amount
end

# ❌ Bad - scattered in capabilities
capability :refund_payment do
  validates { refund_amount <= original_amount }
end
```

### 3. Make State Transitions Explicit

```ruby
# ✅ Good - clear transitions
capability :confirm_payment do
  precondition { status == :pending }
  transitions_to :confirmed
end

# ❌ Bad - implicit state change
capability :confirm_payment do
  sets status: :confirmed
end
```

### 4. Use Computed Fields in Facets

```ruby
# ✅ Good - keep core clean
# In core: just the data
attribute :created_at, :datetime

# In facet: add computed fields
computed :age_in_days do |payment|
  (Time.now - payment.created_at) / 1.day
end

# ❌ Bad - computed in core
attribute :age_in_days, :integer
```

---

## Next Steps

- [Defining Facets](Defining-Facets.md) - Create consumer-specific views
- [API Generation](API-Generation.md) - See how endpoints are generated
- [Examples](Examples.md) - Complete working examples
