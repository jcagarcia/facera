# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
