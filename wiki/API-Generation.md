# API Generation

How Facera automatically generates REST APIs from your cores and facets.

---

## Overview

Facera generates complete REST APIs automatically:
- No controllers to write
- No routes to define
- No serializers to maintain
- Just define cores and facets

---

## Generated Endpoints

For each entity with allowed capabilities, Facera generates:

### Create

```
POST /{entities}
```

**Example:**
```bash
POST /api/v1/payments
Content-Type: application/json

{
  "amount": 100.0,
  "currency": "USD",
  "merchant_id": "550e8400-...",
  "customer_id": "6ba7b810-..."
}
```

**Response:**
```json
{
  "id": "7c9e6679-...",
  "amount": 100.0,
  "currency": "USD",
  "status": "pending"
}
```

### Get (Single)

```
GET /{entities}/:id
```

**Example:**
```bash
GET /api/v1/payments/7c9e6679-7425-40de-944b-e07fc1f90ae7
```

**Response:**
```json
{
  "id": "7c9e6679-...",
  "amount": 100.0,
  "currency": "USD",
  "status": "pending"
}
```

### List (Multiple)

```
GET /{entities}?filter1=value1&filter2=value2
```

**Example:**
```bash
GET /api/v1/payments?merchant_id=550e8400&status=pending
```

**Response:**
```json
[
  {
    "id": "7c9e6679-...",
    "amount": 100.0,
    "currency": "USD",
    "status": "pending"
  },
  {
    "id": "8d0f7780-...",
    "amount": 250.0,
    "currency": "EUR",
    "status": "pending"
  }
]
```

### Actions

```
POST /{entities}/:id/{action_name}
```

**Example:**
```bash
POST /api/internal/v1/payments/7c9e6679-7425-40de-944b-e07fc1f90ae7/confirm
Content-Type: application/json

{
  "confirmation_code": "ABC123"
}
```

**Response:**
```json
{
  "id": "7c9e6679-...",
  "amount": 100.0,
  "currency": "USD",
  "status": "confirmed",
  "confirmed_at": "2026-03-09T10:30:00Z"
}
```

### Health Check

```
GET /health
```

**Example:**
```bash
GET /api/v1/health
```

**Response:**
```json
{
  "status": "ok",
  "facet": "external",
  "core": "payment",
  "timestamp": "2026-03-09T10:30:00Z"
}
```

---

## Path Generation

Facera generates paths based on configuration:

```ruby
Facera.configure do |config|
  config.base_path = '/api'
  config.version = 'v1'
  config.facet_path :external, '/v1'
  config.facet_path :internal, '/internal/v1'
end
```

**Results in:**
```
/api/v1/payments                    (external)
/api/internal/v1/payments           (internal)
```

---

## Different Facets, Different APIs

### External Facet

```ruby
Facera.define_facet(:external, core: :payment) do
  expose :payment do
    fields :id, :amount, :currency, :status
  end
  allow_capabilities :create_payment, :get_payment
end
```

**Generated:**
```
POST /api/v1/payments
GET  /api/v1/payments/:id
```

### Internal Facet

```ruby
Facera.define_facet(:internal, core: :payment) do
  expose :payment do
    fields :all
  end
  allow_capabilities :all
end
```

**Generated:**
```
POST /api/internal/v1/payments
GET  /api/internal/v1/payments/:id
GET  /api/internal/v1/payments
POST /api/internal/v1/payments/:id/confirm
POST /api/internal/v1/payments/:id/cancel
POST /api/internal/v1/payments/:id/refund
```

---

## Request/Response Format

### Request Body

JSON format with entity attributes:

```json
{
  "attribute1": "value1",
  "attribute2": 123,
  "attribute3": true
}
```

### Response Body

JSON format with exposed fields:

```json
{
  "id": "...",
  "field1": "value1",
  "field2": 123,
  "computed_field": "computed value"
}
```

### Error Response

Format depends on `error_verbosity`:

**Minimal:**
```json
{
  "error": "Validation failed"
}
```

**Detailed:**
```json
{
  "error": "Validation failed",
  "message": "Amount must be positive",
  "field": "amount"
}
```

**Structured:**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Amount must be positive",
    "field": "amount",
    "value": -100,
    "constraint": "amount > 0"
  }
}
```

---

## Query Parameters

### Filtering

For list endpoints with filterable fields:

```bash
GET /payments?merchant_id=550e8400&status=pending&currency=USD
```

### Sorting

For list endpoints with sortable fields:

```bash
GET /payments?sort=created_at&order=desc
```

### Pagination

```bash
GET /payments?limit=20&offset=40
```

---

## HTTP Status Codes

Facera uses standard HTTP status codes:

| Code | Meaning | When Used |
|------|---------|-----------|
| `200` | OK | Successful GET, action |
| `201` | Created | Successful POST (create) |
| `400` | Bad Request | Validation error |
| `401` | Unauthorized | Authentication failed |
| `403` | Forbidden | Authorization failed |
| `404` | Not Found | Entity not found |
| `422` | Unprocessable | Business rule violation |
| `500` | Server Error | Unexpected error |

---

## Complete Example

### Core Definition

```ruby
Facera.define_core(:payment) do
  entity :payment do
    attribute :id, :uuid, immutable: true
    attribute :amount, :money, required: true
    attribute :status, :enum, values: [:pending, :confirmed]
  end

  capability :create_payment, type: :create do
    entity :payment
    requires :amount
  end

  capability :confirm_payment, type: :action do
    entity :payment
    transitions_to :confirmed
  end
end
```

### Facet Definition

```ruby
Facera.define_facet(:external, core: :payment) do
  expose :payment do
    fields :id, :amount, :status
  end
  allow_capabilities :create_payment
end
```

### Generated API

```bash
# Create payment
curl -X POST http://localhost:9292/api/v1/payments \
  -H 'Content-Type: application/json' \
  -d '{"amount": 100.0}'

# Response
{
  "id": "7c9e6679-...",
  "amount": 100.0,
  "status": "pending"
}

# Get payment
curl http://localhost:9292/api/v1/payments/7c9e6679-...

# Response
{
  "id": "7c9e6679-...",
  "amount": 100.0,
  "status": "pending"
}

# Try to confirm (not allowed in external facet)
curl -X POST http://localhost:9292/api/v1/payments/7c9e6679-.../confirm

# Response
{
  "error": "Not Found"
}
```

---

## Behind the Scenes

Facera uses [Grape](https://github.com/ruby-grape/grape) to generate APIs:

1. **Discovery**: Loader finds all cores and facets
2. **Registration**: Registry stores core and facet definitions
3. **Generation**: APIGenerator creates Grape::API classes
4. **Mounting**: AutoMount mounts generated APIs at configured paths

```ruby
# Generated internally (you don't write this)
class ExternalAPI < Grape::API
  format :json

  resource :payments do
    post do
      # create_payment logic
    end

    route_param :id do
      get do
        # get_payment logic
      end
    end
  end
end
```

---

## Next Steps

- [Auto-Mounting](Auto-Mounting.md) - How APIs are discovered and mounted
- [Configuration](Configuration.md) - Customize paths and authentication
- [Introspection](Introspection.md) - Explore generated APIs at runtime
