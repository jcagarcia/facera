# Architecture

Deep dive into Facera's design principles and internal architecture.

---

## Design Principles

### 1. Single Source of Truth

Define your domain once in the core:
- Business logic
- Validation rules
- State transitions
- Invariants

All facets inherit this automatically.

### 2. Facet-Oriented

Different consumers need different views:
- **External clients** - Limited data, minimal errors
- **Internal services** - Full data, detailed errors
- **Operators** - Everything + audit trails
- **Agents** - Machine-readable formats

### 3. Convention Over Configuration

Auto-discovery eliminates boilerplate:
- Cores in `cores/` directory
- Facets in `facets/` directory
- No manual registration required
- Sensible defaults everywhere

### 4. Zero Duplication

APIs are generated, not written:
- No controllers
- No serializers
- No routes
- Just cores and facets

### 5. Consistency by Design

All facets share core logic:
- Same validations
- Same state transitions
- Same business rules
- Guaranteed consistency

---

## System Architecture

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
│  Loader → Registry → APIGenerator → AutoMount               │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                    Generated REST APIs                       │
├─────────────────────────────────────────────────────────────┤
│  /api/v1              - External API                        │
│  /api/internal/v1     - Internal API                        │
│  /api/operator/v1     - Operator API                        │
│  /api/facera          - Introspection                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Loader

**Purpose:** Auto-discover and load cores and facets

**Location:** `lib/facera/loader.rb`

**Responsibilities:**
- Detect load paths (`cores/`, `app/cores/`, `lib/cores/`)
- Find all `.rb` files
- Load cores first, facets second
- Handle dependencies

**Example:**
```ruby
loader = Facera::Loader.new
loader.load_all!
```

### 2. Registry

**Purpose:** Store core and facet definitions

**Location:** `lib/facera/registry.rb`

**Responsibilities:**
- Register cores
- Register facets
- Provide lookup by name
- Validate references

**Example:**
```ruby
Facera::Registry.register_core(:payment, core_definition)
Facera::Registry.register_facet(:external, facet_definition)

core = Facera::Registry.cores[:payment]
facet = Facera::Registry.facets[:external]
```

### 3. Core DSL

**Purpose:** Define domain model

**Location:** `lib/facera/core.rb`

**Components:**
- `Core` - Container for entities and capabilities
- `Entity` - Domain object definition
- `Attribute` - Entity field definition
- `Capability` - Action definition
- `Invariant` - Business rule

**Example:**
```ruby
Facera.define_core(:payment) do
  entity :payment do
    attribute :id, :uuid
  end

  capability :create_payment, type: :create do
    entity :payment
  end

  invariant :positive_amount do
    amount > 0
  end
end
```

### 4. Facet DSL

**Purpose:** Define consumer-specific projections

**Location:** `lib/facera/facet.rb`

**Components:**
- `Facet` - Container for projections
- `FieldVisibility` - Control exposed fields
- `CapabilityAccess` - Control allowed capabilities

**Example:**
```ruby
Facera.define_facet(:external, core: :payment) do
  expose :payment do
    fields :id, :amount
  end

  allow_capabilities :create_payment
end
```

### 5. API Generator

**Purpose:** Generate Grape APIs from facets

**Location:** `lib/facera/grape/api_generator.rb`

**Responsibilities:**
- Generate REST endpoints
- Map capabilities to HTTP methods
- Apply field visibility
- Handle errors

**Generated:**
```ruby
class ExternalAPI < Grape::API
  resource :payments do
    post { ... }
    route_param :id do
      get { ... }
    end
  end
end
```

### 6. Auto Mount

**Purpose:** Mount generated APIs

**Location:** `lib/facera/auto_mount.rb`

**Responsibilities:**
- Discover definitions
- Generate APIs
- Mount at paths
- Add introspection

**Example:**
```ruby
Facera.auto_mount!(app)
```

### 7. Introspection

**Purpose:** Runtime exploration

**Location:** `lib/facera/introspection.rb`

**Provides:**
- Core inspection
- Facet inspection
- Mounted configuration

**Example:**
```ruby
Facera::Introspection.inspect_cores
Facera::Introspection.inspect_facet(:external)
```

### 8. OpenAPI Generator

**Purpose:** Generate OpenAPI specs

**Location:** `lib/facera/openapi_generator.rb`

**Generates:**
- Paths
- Schemas
- Parameters
- Responses

**Example:**
```ruby
Facera::OpenAPIGenerator.for_facet(:external)
```

---

## Request Flow

### 1. Incoming Request

```
HTTP Request
  ↓
Rack Middleware Stack
  ↓
URLMap Router
  ↓
Generated Grape API
```

### 2. API Processing

```
Grape API
  ↓
Endpoint Handler
  ↓
Capability Execution
  ↓
Core Validation
  ↓
Facet Filtering
  ↓
Response Serialization
```

### 3. Example Flow

```
POST /api/v1/payments
  ↓
ExternalAPI (Grape)
  ↓
create_payment capability
  ↓
Core validation (amount > 0)
  ↓
Facet filtering (only expose id, amount, status)
  ↓
JSON response
```

---

## Data Flow

### Core Definition → API Generation

```ruby
# 1. Define core
Facera.define_core(:payment) do
  entity :payment do
    attribute :id, :uuid
    attribute :amount, :money
  end

  capability :create_payment, type: :create do
    entity :payment
    requires :amount
  end
end

# 2. Define facet
Facera.define_facet(:external, core: :payment) do
  expose :payment do
    fields :id, :amount
  end
  allow_capabilities :create_payment
end

# 3. Generate API
api = Facera::Grape::APIGenerator.for_facet(:external)

# 4. Generated endpoints
POST /payments
```

### Request → Response

```ruby
# Request
POST /api/v1/payments
{
  "amount": 100.0,
  "currency": "USD"
}

# Capability execution
capability = core.capabilities[:create_payment]
capability.execute(params)

# Core validation
invariant :positive_amount
amount > 0 ✓

# Facet filtering
visible_fields = [:id, :amount, :status]
response = payment.slice(*visible_fields)

# Response
201 Created
{
  "id": "7c9e6679-...",
  "amount": 100.0,
  "status": "pending"
}
```

---

## Framework Integration

### Rails

```ruby
# Automatic integration via Railtie
module Facera
  class Railtie < Rails::Railtie
    initializer "facera.load" do
      Facera::Loader.new(load_paths: [Rails.root]).load_all!
    end
  end
end
```

### Sinatra

```ruby
Facera.auto_mount!(Sinatra::Application)
```

### Pure Rack

```ruby
Rack::Builder.new do
  Facera.auto_mount!(self)
end
```

---

## Extension Points

### 1. Custom Capabilities

```ruby
class Facera::Capability
  def custom_behavior
    # Add custom capability logic
  end
end
```

### 2. Custom Field Types

```ruby
Facera.register_type(:custom_type) do |value|
  # Custom type coercion
end
```

### 3. Custom Middleware

```ruby
Facera.configure do |config|
  config.middleware.use CustomMiddleware
end
```

### 4. Custom Error Handling

```ruby
Facera.configure do |config|
  config.error_handler do |error, facet|
    # Custom error handling
  end
end
```

---

## Testing Architecture

### Unit Tests

Test individual components:
```ruby
RSpec.describe Facera::Core do
  it "registers entities" do
    core = Facera::Core.new(:payment)
    core.entity(:payment) { }
    expect(core.entities).to have_key(:payment)
  end
end
```

### Integration Tests

Test full request flow:
```ruby
RSpec.describe "External API" do
  include Rack::Test::Methods

  def app
    Facera.auto_mount!(Rack::Builder.new)
  end

  it "creates payment" do
    post '/api/v1/payments', {...}.to_json
    expect(last_response.status).to eq(201)
  end
end
```

---

## Performance Considerations

### 1. Preloading

Load cores and facets at boot:
```ruby
preload_app!  # Puma/Unicorn
```

### 2. Caching

Cache generated APIs:
```ruby
Facera.configure do |config|
  config.cache_apis = true
end
```

### 3. Connection Pooling

Configure database pools:
```ruby
config.pool = 5
```

### 4. Lazy Loading

Load facets on demand:
```ruby
Facera.load_facet(:external)  # Only when needed
```

---

## Security Architecture

### 1. Authentication Layer

```ruby
config.authenticate :external do |request|
  # Verify token
end
```

### 2. Authorization Layer

```ruby
# In facet
scope :list_payments do |query|
  query.where(merchant_id: current_merchant.id)
end
```

### 3. Field Filtering

```ruby
expose :payment do
  fields :id, :amount  # Hide sensitive fields
end
```

### 4. Capability Access

```ruby
allow_capabilities :create, :read  # Deny write/delete
```

---

## Next Steps

- [Examples](Examples.md) - See it in action
- [Contributing](Contributing.md) - Contribute to Facera
