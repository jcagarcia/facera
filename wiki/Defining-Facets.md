# Defining Facets

Complete guide to defining consumer-specific API projections.

---

## Basic Structure

```ruby
Facera.define_facet(:facet_name, core: :core_name) do
  description "Description of this facet"

  expose :entity_name do
    # field visibility
  end

  allow_capabilities :capability1, :capability2

  # additional options
end
```

---

## Field Visibility

Control which entity fields are exposed to consumers.

### Explicit Field List

```ruby
expose :payment do
  fields :id, :amount, :currency, :status
end
```

### Expose All Fields

```ruby
expose :payment do
  fields :all
end
```

### Hide Specific Fields

```ruby
expose :payment do
  fields :all
  hide :merchant_internal_id, :processing_fee
end
```

### Field Aliases

```ruby
expose :payment do
  fields :id, :amount, :currency
  alias_field :amount, as: :total
  alias_field :currency, as: :currency_code
end
```

### Computed Fields

Add derived data not in the core:

```ruby
expose :payment do
  fields :all

  computed :display_amount do |payment|
    "#{payment.currency} #{payment.amount}"
  end

  computed :processing_time do |payment|
    Time.now - payment.created_at
  end

  computed :is_high_value do |payment|
    payment.amount > 10000
  end
end
```

---

## Capability Access Control

Control which capabilities are available in this facet.

### Allow Specific Capabilities

```ruby
# Only allow certain actions
allow_capabilities :create_payment, :get_payment, :list_payments
```

### Allow All Capabilities

```ruby
# Allow everything from the core
allow_capabilities :all
```

### Deny Specific Capabilities

```ruby
# Allow all except specific ones
allow_capabilities :all
deny_capabilities :delete_payment, :refund_payment
```

### By Type

```ruby
# Allow all reads but no writes
allow_capabilities :get_payment, :list_payments

# Allow all actions
allow_capabilities :confirm_payment, :cancel_payment, :refund_payment
```

---

## Capability Scoping

Add automatic filtering to capabilities.

### Filter Lists

```ruby
Facera.define_facet(:merchant, core: :payment) do
  # Automatically filter by current merchant
  scope :list_payments do |query|
    query.where(merchant_id: current_merchant.id)
  end
end
```

### Filter Individual Retrievals

```ruby
scope :get_payment do |payment|
  # Only return if belongs to merchant
  payment if payment.merchant_id == current_merchant.id
end
```

### Add Conditions to Actions

```ruby
scope :confirm_payment do |payment|
  # Only allow if merchant owns payment
  raise Facera::UnauthorizedError unless payment.merchant_id == current_merchant.id
  payment
end
```

---

## Error Handling

Control error verbosity for different consumers.

### Minimal (External APIs)

```ruby
error_verbosity :minimal
```

Returns:
```json
{
  "error": "Validation failed"
}
```

### Detailed (Internal APIs)

```ruby
error_verbosity :detailed
```

Returns:
```json
{
  "error": "Validation failed",
  "message": "Amount must be positive",
  "field": "amount",
  "stacktrace": [...]
}
```

### Structured (Operators)

```ruby
error_verbosity :structured
```

Returns:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Amount must be positive",
    "field": "amount",
    "value": -100,
    "constraint": "amount > 0",
    "timestamp": "2026-03-09T10:30:00Z",
    "request_id": "abc123"
  }
}
```

---

## Additional Options

### Description

```ruby
description "Public API for external clients"
```

### Format

```ruby
format :json  # or :xml, :msgpack
```

### Rate Limiting

```ruby
rate_limit requests: 1000, per: :hour
rate_limit requests: 100, per: :minute
```

### Audit Logging

```ruby
# Log all operations
audit_all_operations user: :current_user

# Log with additional context
audit_all_operations user: :current_user, ip: :remote_ip, session: :session_id

# Log specific capabilities
audit_capabilities :confirm_payment, :refund_payment
```

### Authentication

```ruby
require_authentication method: :bearer_token
require_authentication method: :api_key, header: 'X-API-Key'
```

---

## Complete Examples

### External Facet (Public API)

```ruby
Facera.define_facet(:external, core: :payment) do
  description "Public API for external clients"

  expose :payment do
    # Limited fields only
    fields :id, :amount, :currency, :status

    # User-friendly computed field
    computed :display_amount do |payment|
      "#{payment.currency} #{payment.amount}"
    end
  end

  # Only safe operations
  allow_capabilities :create_payment, :get_payment, :list_payments

  # Minimal errors
  error_verbosity :minimal

  # Rate limiting
  rate_limit requests: 1000, per: :hour

  # Authentication required
  require_authentication method: :bearer_token
end
```

### Internal Facet (Service-to-Service)

```ruby
Facera.define_facet(:internal, core: :payment) do
  description "Service-to-service API"

  expose :payment do
    # All fields
    fields :all

    # Technical computed fields
    computed :processing_time do |payment|
      Time.now - payment.created_at
    end

    computed :days_since_creation do |payment|
      ((Time.now - payment.created_at) / 1.day).to_i
    end
  end

  # All capabilities available
  allow_capabilities :all

  # Detailed errors for debugging
  error_verbosity :detailed

  # Service authentication
  require_authentication method: :service_token, header: 'X-Service-Token'
end
```

### Merchant Facet (Scoped Access)

```ruby
Facera.define_facet(:merchant, core: :payment) do
  description "API for merchant dashboard"

  expose :payment do
    fields :id, :amount, :currency, :status, :customer_id, :created_at
    hide :merchant_id  # Don't expose own ID

    computed :customer_name do |payment|
      Customer.find(payment.customer_id).name
    end
  end

  # Basic operations
  allow_capabilities :create_payment, :get_payment, :list_payments, :cancel_payment
  deny_capabilities :refund_payment  # Only operators can refund

  # Automatic filtering by merchant
  scope :list_payments do |query|
    query.where(merchant_id: current_merchant.id)
  end

  scope :get_payment do |payment|
    payment if payment.merchant_id == current_merchant.id
  end

  scope :cancel_payment do |payment|
    raise Facera::UnauthorizedError unless payment.merchant_id == current_merchant.id
    payment
  end

  error_verbosity :structured
  rate_limit requests: 5000, per: :hour
  audit_all_operations user: :current_merchant
end
```

### Operator Facet (Admin)

```ruby
Facera.define_facet(:operator, core: :payment) do
  description "Admin API for operators"

  expose :payment do
    # Everything including internal fields
    fields :all

    # Admin-specific computed fields
    computed :audit_trail do |payment|
      PaymentAudit.where(payment_id: payment.id).to_a
    end

    computed :risk_score do |payment|
      FraudDetection.score_for(payment)
    end
  end

  # All capabilities
  allow_capabilities :all

  # Full error details
  error_verbosity :structured

  # Log everything
  audit_all_operations user: :admin_user, ip: :remote_ip, action: :admin_action

  # Admin authentication
  require_authentication method: :admin_token
end
```

### Agent Facet (Machine-Readable)

```ruby
Facera.define_facet(:agent, core: :payment) do
  description "Machine-readable API for AI agents"

  expose :payment do
    # Semantic fields only
    fields :id, :amount, :currency, :status, :created_at

    # Machine-readable metadata
    computed :state_transitions do |payment|
      {
        current: payment.status,
        available: available_transitions_for(payment),
        history: payment.status_history
      }
    end

    computed :capabilities do |payment|
      available_capabilities_for(payment)
    end
  end

  # All reads and standard actions
  allow_capabilities :get_payment, :list_payments, :confirm_payment, :cancel_payment
  deny_capabilities :refund_payment  # Requires human approval

  # Structured errors for parsing
  error_verbosity :structured

  # High rate limit for agents
  rate_limit requests: 10000, per: :hour

  # Agent authentication
  require_authentication method: :api_key
end
```

---

## Best Practices

### 1. Name Facets by Consumer

```ruby
# ✅ Good - clear consumer
:external, :internal, :merchant, :operator, :agent

# ❌ Bad - implementation detail
:v1, :v2, :api_a, :api_b
```

### 2. Start Restrictive

```ruby
# ✅ Good - start minimal
fields :id, :amount, :status
allow_capabilities :create_payment, :get_payment

# ❌ Bad - expose everything
fields :all
allow_capabilities :all
```

### 3. Use Computed Fields for Presentation

```ruby
# ✅ Good - presentation in facet
computed :display_amount do |payment|
  "#{payment.currency} #{payment.amount}"
end

# ❌ Bad - presentation in core
attribute :display_amount, :string
```

### 4. Scope by Default

```ruby
# ✅ Good - automatic scoping
scope :list_payments do |query|
  query.where(merchant_id: current_merchant.id)
end

# ❌ Bad - manual filtering required
# Relies on consumer to filter correctly
```

---

## Next Steps

- [API Generation](API-Generation.md) - See how endpoints are generated
- [Configuration](Configuration.md) - Authentication and paths
- [Examples](Examples.md) - Complete working examples
