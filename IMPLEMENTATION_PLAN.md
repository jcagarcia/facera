# Facera Implementation Plan

## Overview

Facera is a Ruby framework for building multi-facet APIs from a single semantic core. This plan outlines the implementation phases to build a complete, production-ready gem.

## Architecture Goals

- **DSL-First**: Declarative DSL for defining cores, entities, capabilities, and facets
- **Auto-Generation**: Automatic Grape API endpoint generation from DSL
- **Auto-Mounting**: Zero-config mounting of all facets with sensible conventions
- **Rails Integration**: Seamless integration via Railtie with generators
- **Documentation**: Auto-generated OpenAPI specs and interactive dashboard
- **Type Safety**: Validation and type checking throughout

---

## Phase 1: Core DSL Foundation

### 1.1 Core Module Structure

**Files to create:**
- `lib/facera/core.rb`
- `lib/facera/dsl/core_definition.rb`
- `lib/facera/registry.rb`

**Tasks:**
- [ ] Create `Facera::Core` class to represent a semantic core
- [ ] Implement `Facera.define_core(name, &block)` DSL method
- [ ] Build core registry for storing and retrieving cores
- [ ] Add validation for core definitions

**Example:**
```ruby
Facera.define_core(:payment) do
  # Core definition
end
```

### 1.2 Entity Definition

**Files to create:**
- `lib/facera/entity.rb`
- `lib/facera/dsl/entity_definition.rb`
- `lib/facera/attribute.rb`

**Tasks:**
- [ ] Create `Facera::Entity` class
- [ ] Implement `entity(name, &block)` DSL method
- [ ] Create `Facera::Attribute` class with type system
- [ ] Support attribute options: `required`, `immutable`, `default`
- [ ] Implement basic type validations: `:uuid`, `:string`, `:integer`, `:money`, `:timestamp`, `:enum`, `:hash`

**Example:**
```ruby
entity :payment do
  attribute :id, :uuid, immutable: true
  attribute :amount, :money, required: true
  attribute :status, :enum, values: [:pending, :confirmed]
end
```

### 1.3 Invariants

**Files to create:**
- `lib/facera/invariant.rb`
- `lib/facera/dsl/invariant_definition.rb`

**Tasks:**
- [ ] Create `Facera::Invariant` class
- [ ] Implement `invariant(name, &block)` DSL method
- [ ] Add invariant validation engine
- [ ] Support validation context (entity instance)

**Example:**
```ruby
invariant :positive_amount do
  amount > 0
end
```

### 1.4 Capabilities

**Files to create:**
- `lib/facera/capability.rb`
- `lib/facera/dsl/capability_definition.rb`
- `lib/facera/capability_types.rb`

**Tasks:**
- [ ] Create `Facera::Capability` class
- [ ] Implement `capability(name, type:, &block)` DSL method
- [ ] Support capability types: `:create`, `:get`, `:update`, `:delete`, `:list`, `:action`
- [ ] Implement `requires`, `optional`, `precondition`, `validates` DSL
- [ ] Add `transitions_to` for state changes
- [ ] Support `sets` for automatic field updates

**Example:**
```ruby
capability :create_payment, type: :create do
  entity :payment
  requires :amount, :currency
  optional :description
  validates { amount > 0 }
end
```

---

## Phase 2: Facet System

### 2.1 Facet Definition

**Files to create:**
- `lib/facera/facet.rb`
- `lib/facera/dsl/facet_definition.rb`

**Tasks:**
- [ ] Create `Facera::Facet` class
- [ ] Implement `Facera.define_facet(name, core:, &block)` DSL method
- [ ] Link facets to cores
- [ ] Add facet registry

**Example:**
```ruby
Facera.define_facet(:external, core: :payment) do
  # Facet configuration
end
```

### 2.2 Field Visibility Control

**Files to create:**
- `lib/facera/field_visibility.rb`
- `lib/facera/dsl/exposure_definition.rb`

**Tasks:**
- [ ] Implement `expose(entity, &block)` DSL method
- [ ] Support `fields` for explicit field listing
- [ ] Support `hide` for excluding fields
- [ ] Support `alias_field` for renaming fields
- [ ] Support `computed` for calculated fields
- [ ] Create field projection engine

**Example:**
```ruby
expose :payment do
  fields :id, :amount, :currency, :status
  hide :merchant_id, :metadata
  alias_field :created_at, as: :createdAt
  computed :customer_name { Customer.find(customer_id).name }
end
```

### 2.3 Capability Access Control

**Files to create:**
- `lib/facera/capability_access.rb`

**Tasks:**
- [ ] Implement `allow_capabilities(*names)` DSL method
- [ ] Implement `deny_capabilities(*names)` DSL method
- [ ] Support `:all` for all capabilities
- [ ] Create capability filter engine

### 2.4 Capability Scoping

**Files to create:**
- `lib/facera/capability_scoping.rb`

**Tasks:**
- [ ] Implement `scope(capability_name, &block)` DSL method
- [ ] Support automatic filtering based on context
- [ ] Add context access (e.g., `current_user`)

**Example:**
```ruby
scope :list_payments do
  filter { customer_id == current_customer.id }
end
```

### 2.5 Error Handling

**Files to create:**
- `lib/facera/error_handling.rb`
- `lib/facera/errors.rb`

**Tasks:**
- [ ] Implement `error_verbosity` levels: `:minimal`, `:detailed`, `:structured`
- [ ] Create error classes: `ValidationError`, `UnauthorizedError`, `NotFoundError`
- [ ] Build error formatter per verbosity level

---

## Phase 3: Grape Integration

### 3.1 API Generator Core

**Files to create:**
- `lib/facera/grape.rb`
- `lib/facera/grape/api_generator.rb`

**Tasks:**
- [ ] Add `grape` gem dependency
- [ ] Create `Facera::API.for_facet(name)` method
- [ ] Generate Grape::API class dynamically
- [ ] Set up format, version, helpers

### 3.2 Endpoint Generation

**Files to create:**
- `lib/facera/grape/endpoint_generator.rb`

**Tasks:**
- [ ] Implement `generate_create_endpoint`
- [ ] Implement `generate_get_endpoint`
- [ ] Implement `generate_update_endpoint`
- [ ] Implement `generate_delete_endpoint`
- [ ] Implement `generate_list_endpoint`
- [ ] Implement `generate_action_endpoint`
- [ ] Auto-generate resource paths
- [ ] Auto-generate parameter validation
- [ ] Auto-generate descriptions

### 3.3 Entity Serialization

**Files to create:**
- `lib/facera/grape/entity_generator.rb`

**Tasks:**
- [ ] Generate Grape::Entity classes per facet
- [ ] Apply field visibility rules
- [ ] Support computed fields
- [ ] Support field aliasing
- [ ] Create collection entities with metadata

### 3.4 Capability Execution

**Files to create:**
- `lib/facera/executor.rb`

**Tasks:**
- [ ] Create `Facera::Executor.run(facet:, capability:, params:, context:)`
- [ ] Validate parameters against capability definition
- [ ] Check preconditions
- [ ] Apply facet scoping
- [ ] Execute capability logic
- [ ] Validate invariants
- [ ] Return serialized result

---

## Phase 4: Auto-Mounting System

### 4.1 Configuration

**Files to create:**
- `lib/facera/configuration.rb`

**Tasks:**
- [ ] Create `Facera.configure` DSL
- [ ] Support `base_path`, `version` configuration
- [ ] Support custom facet paths via `facet_path`
- [ ] Support `disable_facet` for selective mounting
- [ ] Support authentication blocks per facet
- [ ] Store configuration in thread-safe manner

### 4.2 Auto-Discovery

**Files to create:**
- `lib/facera/auto_mount.rb`

**Tasks:**
- [ ] Create `Facera.auto_mount!(app = nil, config: {})`
- [ ] Auto-detect application type (Rails, Sinatra, Rack)
- [ ] Auto-discover facet files from conventional paths
- [ ] Load all core and facet definitions

### 4.3 Facet Mounting

**Tasks:**
- [ ] Mount each facet at conventional path
- [ ] Support Rails route mounting
- [ ] Support Rack/Sinatra mounting
- [ ] Log mounted facets with paths and endpoint counts
- [ ] Generate route information

### 4.4 Rails Integration

**Files to create:**
- `lib/facera/railtie.rb`

**Tasks:**
- [ ] Create Rails::Railtie for auto-loading
- [ ] Auto-load cores from `app/cores/**/*.rb`
- [ ] Auto-load facets from `app/facets/**/*.rb`
- [ ] Auto-mount after initialization (unless initializer exists)
- [ ] Add `rake facera:routes` task
- [ ] Add generators registration

---

## Phase 5: Dashboard & Documentation

### 5.1 Admin Dashboard

**Files to create:**
- `lib/facera/dashboard.rb`
- `lib/facera/dashboard/views/index.erb`
- `lib/facera/dashboard/views/facet.erb`
- `lib/facera/dashboard/views/core.erb`
- `lib/facera/dashboard/views/playground.erb`

**Tasks:**
- [ ] Build Sinatra-based dashboard
- [ ] Show all cores with entities, capabilities, invariants
- [ ] Show all facets with mounted paths and endpoints
- [ ] Create API playground for testing endpoints
- [ ] Add visual facet comparison view
- [ ] Style with simple CSS (no external dependencies)

### 5.2 Introspection API

**Files to create:**
- `lib/facera/introspection.rb`

**Tasks:**
- [ ] Create `Facera::Introspection.endpoints_for(facet)`
- [ ] List all mounted routes
- [ ] Show capability mappings
- [ ] Show field visibility per facet
- [ ] Generate facet comparison matrix

### 5.3 OpenAPI Generation

**Files to create:**
- `lib/facera/openapi.rb`
- `lib/facera/openapi/generator.rb`

**Tasks:**
- [ ] Implement `Facera::OpenAPI.generate(facet_name)`
- [ ] Generate OpenAPI 3.0 spec from DSL
- [ ] Include all endpoints with parameters
- [ ] Include entity schemas
- [ ] Include authentication schemes
- [ ] Support Swagger UI integration

---

## Phase 6: Code Generation

### 6.1 Rails Generators

**Files to create:**
- `lib/facera/generators/install_generator.rb`
- `lib/facera/generators/core_generator.rb`
- `lib/facera/generators/facet_generator.rb`
- `lib/facera/generators/client_generator.rb`

**Tasks:**
- [ ] Create `rails g facera:install` generator
- [ ] Create `rails g facera:core NAME` generator
- [ ] Create `rails g facera:facet NAME --core=CORE` generator
- [ ] Create `rails g facera:client LANGUAGE --facet=FACET` generator
- [ ] Generate conventional directory structure

### 6.2 Client Code Generation

**Files to create:**
- `lib/facera/codegen.rb`
- `lib/facera/codegen/typescript_generator.rb`
- `lib/facera/codegen/ruby_generator.rb`

**Tasks:**
- [ ] Implement `Facera::Codegen.generate(language, facet:, output:)`
- [ ] Generate TypeScript client from facet
- [ ] Generate Ruby client from facet
- [ ] Include type definitions
- [ ] Include authentication helpers
- [ ] Generate README for client usage

---

## Phase 7: Testing & Quality

### 7.1 Test Suite

**Tasks:**
- [ ] Write RSpec tests for DSL parsing
- [ ] Test core/entity/capability/facet definitions
- [ ] Test Grape API generation
- [ ] Test auto-mounting
- [ ] Test field visibility and scoping
- [ ] Test invariant validation
- [ ] Test error handling
- [ ] Achieve 90%+ code coverage

### 7.2 Integration Tests

**Tasks:**
- [ ] Create test Rails app in `spec/dummy`
- [ ] Test full stack: DSL → API → HTTP responses
- [ ] Test authentication integration
- [ ] Test dashboard functionality
- [ ] Test OpenAPI generation

### 7.3 Documentation

**Tasks:**
- [ ] Write comprehensive README with examples
- [ ] Create GETTING_STARTED guide
- [ ] Document all DSL methods with examples
- [ ] Create API reference documentation
- [ ] Add inline code documentation (YARD)
- [ ] Create example applications

---

## Phase 8: Advanced Features

### 8.1 Middleware Support

**Files to create:**
- `lib/facera/middleware.rb`

**Tasks:**
- [ ] Support custom middleware per facet
- [ ] Built-in rate limiting middleware
- [ ] Built-in audit logging middleware
- [ ] Built-in caching middleware

### 8.2 Versioning

**Files to create:**
- `lib/facera/versioning.rb`

**Tasks:**
- [ ] Support API versioning per facet
- [ ] Support breaking change detection
- [ ] Generate migration guides between versions

### 8.3 Performance

**Tasks:**
- [ ] Add caching for facet/core lookups
- [ ] Optimize endpoint generation (cache generated classes)
- [ ] Add performance benchmarks
- [ ] Profile memory usage

### 8.4 Observability

**Files to create:**
- `lib/facera/instrumentation.rb`

**Tasks:**
- [ ] Add ActiveSupport::Notifications instrumentation
- [ ] Emit events for capability execution
- [ ] Emit events for validation failures
- [ ] Support custom instrumentation hooks

---

## Implementation Order

### Sprint 1 (Week 1-2): Foundation
1. Phase 1.1-1.4: Core DSL (Core, Entity, Invariants, Capabilities)
2. Basic registry and validation

### Sprint 2 (Week 3-4): Facets
3. Phase 2.1-2.5: Facet system (Definition, Visibility, Access, Scoping, Errors)

### Sprint 3 (Week 5-6): Grape Integration
4. Phase 3.1-3.4: Grape API generation (Generator, Endpoints, Entities, Executor)

### Sprint 4 (Week 7-8): Auto-Mounting
5. Phase 4.1-4.4: Auto-mounting system (Configuration, Discovery, Mounting, Rails)

### Sprint 5 (Week 9-10): Dashboard
6. Phase 5.1-5.3: Dashboard and documentation (Admin UI, Introspection, OpenAPI)

### Sprint 6 (Week 11-12): Generators
7. Phase 6.1-6.2: Code generation (Rails generators, Client generation)

### Sprint 7 (Week 13-14): Testing & Polish
8. Phase 7.1-7.3: Testing and documentation
9. Phase 8: Advanced features (as time permits)

---

## Success Criteria

- [ ] DSL is intuitive and Ruby-idiomatic
- [ ] Zero-config works out of the box for 90% of use cases
- [ ] Generated APIs follow REST best practices
- [ ] Dashboard provides clear visibility into all facets
- [ ] Documentation is comprehensive and includes examples
- [ ] Test coverage > 90%
- [ ] Performance is acceptable for production use
- [ ] Rails integration feels native

---

## Dependencies

```ruby
# facera.gemspec
spec.add_dependency "grape", "~> 2.0"
spec.add_dependency "grape-entity", "~> 1.0"
spec.add_dependency "sinatra", "~> 3.0"  # for dashboard

spec.add_development_dependency "rails", ">= 6.0"
spec.add_development_dependency "rspec", "~> 3.0"
spec.add_development_dependency "rack-test", "~> 2.0"
```

---

## Release Plan

### v0.1.0 (Alpha) - Core DSL
- Basic DSL working
- Manual API generation
- No auto-mounting

### v0.2.0 (Beta) - Auto-Generation
- Grape API auto-generation
- Basic auto-mounting
- Simple dashboard

### v0.3.0 (Beta) - Rails Integration
- Rails Railtie
- Generators
- OpenAPI generation

### v1.0.0 (Stable) - Production Ready
- Full feature set
- Comprehensive tests
- Complete documentation
- Real-world examples
