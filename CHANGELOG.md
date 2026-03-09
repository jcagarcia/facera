# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-03-09

### Added

#### Audience-Grouped APIs
- **Multi-core audience grouping** — facets sharing the same audience name across different cores are now automatically merged into a single mounted API
  - `define_facet(:public, core: :payment)` + `define_facet(:public, core: :refund)` → one API at `/api/public/v1` serving `/payments` and `/refunds`
  - No configuration required; grouping happens by convention
- **`Registry.facet_groups`** — new method returning facets grouped by audience name (`{ public: [facet_payment, facet_refund], ... }`)
- **`Grape::APIGenerator.for_group(audience_name, facets)`** — generates a single merged Grape API class from multiple facets across different cores
- **`/facera/audiences` endpoint** — new introspection endpoint returning all audiences with their path, cores, resources, and per-facet configuration
- **`Introspection.inspect_audiences`** — programmatic audience inspection including path, resource list, and capability summary per contributing core
- **Dashboard UI** — new web dashboard mounted at `/facera/ui` with:
  - Overview page showing audience-grouped API cards with mount path, resources, and per-core details
  - APIs list and detail pages (`/apis`, `/apis/:name`)
  - Facets list and detail pages (`/facets`, `/facets/:name`)
  - Cores list and detail pages (`/cores`, `/cores/:name`)
  - Swagger UI integration for per-audience OpenAPI rendering (`/openapi/:name`)
  - SPA client-side routing with deep-link support

#### OpenAPI Generation
- **Combined audience OpenAPI spec** — `GET /facera/openapi/:name` now generates a single spec covering all cores in the audience (e.g. `/public` spec includes both `/payments` and `/refunds` paths)
- `OpenAPIGenerator` is now audience-aware: initialized with an audience name, iterates all contributing facets and cores

### Changed

- **Facet DSL** — `define_facet` signature now requires `core:` keyword: `define_facet(:audience_name, core: :core_name)`; the audience name is the facet name (no more per-core suffixes)
- **Registry storage** — facets are stored internally under composite keys `:"audience:core"` (e.g. `:"public:payment"`) to avoid collisions; external lookups by audience name still work
- **`auto_mount.rb`** — now iterates `Registry.facet_groups` instead of individual facets, mounting one Grape API per audience
- **`configuration.rb`** — `default_path_for` simplified to `/{audience}/{version}` for all audience names; removed hardcoded special-casing for `:external`, `:internal`, `:operator`
- **Health endpoint** — response now returns `audience` and `cores` array instead of `facet` and `core` to reflect the grouped model
- **Startup log** — now shows audience count alongside facet count and lists contributing cores per mounted audience
- **Examples** — example facets renamed to generic audience names (`public`, `internal`, `ops`) and restructured to one file per core (`payment_facets.rb`, `refund_facets.rb`) demonstrating the grouped model

### Fixed

- **`inspect_facets`** — fixed to use composite registry keys correctly, returning `facet.name` (audience name) instead of the raw registry key
- **`inspect_core`** — fixed iterator destructuring for `core.invariants` (now uses `|_inv_name, inv|`)
- **`inspect_facet`** — fixed lookup to scan by audience name when composite key not found
- **`Facet#visible_fields_for`** — fixed `nil` guard when entity is not found in core
- **Dashboard `badgeList`** — fixed crash when `visible_fields` is `"all"` (Ruby `:all` symbol serialized as JSON string); strings are no longer passed to `.map()`

### Breaking Changes

- `Registry.register_facet` now takes three arguments: `register_facet(audience_name, core_name, facet)`
- Facets are no longer keyed by a plain audience name in the registry; use `Registry.facet_groups[audience_name]` to retrieve all facets for an audience
- `OpenAPIGenerator.new` now accepts an audience name (not a facet/composite key); raises if the audience is not found
- Example facet files restructured: `external_facet.rb`, `internal_facet.rb`, `operator_facet.rb` replaced by `payment_facets.rb` and `refund_facets.rb`

### Migration Guide

**Before (0.1.x):**
```ruby
Facera.define_facet(:external_payment, core: :payment) { ... }
Facera.define_facet(:external_refund, core: :refund) { ... }
# Mounted as two separate APIs
```

**After (0.2.0):**
```ruby
Facera.define_facet(:public, core: :payment) { ... }
Facera.define_facet(:public, core: :refund) { ... }
# Automatically merged into one API at /api/public/v1
# serving /payments and /refunds
```

## [0.1.0] - 2026-03-09

### Added

#### Core Framework
- **Core DSL** - Define domain models with entities, capabilities, and invariants
  - Entity definitions with typed attributes (string, integer, uuid, money, enum, etc.)
  - Four capability types: create, get, list, action
  - Business invariants with validation blocks
  - State transitions and preconditions
  - Field setters and required/optional parameters

- **Facet System** - Consumer-specific API projections
  - Field visibility control (explicit fields, hide fields, expose all)
  - Capability access control (allow/deny capabilities)
  - Computed fields with custom logic
  - Error verbosity levels (minimal, detailed, structured)
  - Audit logging configuration
  - Capability scoping for filtering

- **Adapter Pattern** - Business logic implementation
  - Adapter base module for implementing capabilities
  - Auto-discovery from `adapters/` directory
  - Auto-linking to cores by naming convention
  - Inline execute blocks for simple logic
  - Priority system (execute block > adapter > mock)
  - Full method naming convention support

- **API Generation** - Auto-generated REST APIs using Grape
  - REST endpoints for all capabilities (POST, GET, LIST)
  - Action endpoints (POST /{entity}/:id/{action})
  - Health check endpoints
  - Automatic parameter validation
  - Automatic precondition checking
  - Invariant validation
  - Field filtering by facet

- **Auto-Mounting** - Convention over configuration
  - Auto-discovery from `cores/`, `adapters/`, and `facets/` directories
  - Support for multiple directory structures (app/, lib/, root)
  - Automatic Grape API generation and mounting
  - Rack::Builder integration
  - Rails Railtie integration
  - Startup logging with emoji indicators 💎🔌🎭🚀📚✨

- **Introspection API** - Runtime API exploration
  - Full introspection endpoint (`/facera/introspect`)
  - Core inspection (`/facera/cores`, `/facera/cores/:name`)
  - Facet inspection (`/facera/facets`, `/facera/facets/:name`)
  - Mounted configuration endpoint (`/facera/mounted`)
  - Programmatic introspection via `Facera::Introspection`

- **OpenAPI Generation** - Auto-generated API documentation
  - OpenAPI 3.0 spec generation for all facets
  - Complete paths, schemas, parameters, and responses
  - Per-facet specs (`/facera/openapi/:facet`)
  - All facets spec (`/facera/openapi`)
  - Programmatic generation via `Facera::OpenAPIGenerator`

- **Configuration System**
  - Base path and versioning
  - Custom facet paths
  - Conditional facet enabling/disabling
  - Feature flags (introspection, dashboard, docs)
  - Authentication hooks per facet

#### Developer Experience
- **Examples** - Five complete working examples
  - 01_core_dsl.rb - Core definition basics
  - 02_facet_system.rb - Multiple facets from one core
  - 03_api_generation.rb - Auto-generated APIs
  - 04_auto_mounting.rb - Zero-config mounting
  - 05_adapters.rb - Business logic implementation
  - Runnable server in examples/server/

- **Documentation** - Comprehensive wiki
  - Home - Complete navigation and quick reference
  - Core Concepts - Understanding the facet model
  - Defining Cores - Entity and capability guide
  - Defining Facets - Field visibility and access control
  - Implementing Business Logic - Adapter pattern guide
  - API Generation - REST endpoint documentation
  - Auto-Mounting - Convention-based discovery guide
  - Configuration - Authentication and feature flags
  - Introspection - Runtime exploration guide
  - Examples - Complete working examples
  - Deployment - Production deployment guides
  - Architecture - Design principles and internals
  - Contributing - Contribution guidelines

- **Testing** - Complete test suite
  - 82 RSpec examples covering all components
  - Core DSL tests
  - Facet system tests
  - Loader and registry tests
  - Configuration tests
  - 100% test coverage for critical paths

- **CI/CD** - GitHub Actions workflow
  - Ruby CI for versions 3.2, 3.3, 3.4, 4.0
  - Automated test runs on push/PR
  - Build status badge in README

#### Internal Infrastructure
- Registry system for cores and facets
- Loader with auto-discovery
- Executor with capability execution logic
- Error formatter with verbosity levels
- Custom Context class (Ruby 4 compatible, replaces OpenStruct)
- Grape API generator
- Grape entity generator with computed fields

### Technical Details
- **Ruby Version**: Requires Ruby >= 3.2.0
- **Dependencies**:
  - grape ~> 2.0
  - grape-entity ~> 1.0
- **License**: MIT
- **Framework Integration**: Rack, Rails, Sinatra

### Breaking Changes
- This is the initial release, no breaking changes

### Migration Guide
- N/A (initial release)

### Contributors
- Juan Carlos Garcia (@jcagarcia)
