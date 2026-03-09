# Facera Wiki

Welcome to the Facera documentation! This wiki provides comprehensive guides for building multi-facet APIs from a single semantic core.

---

## What is Facera?

Facera is a Ruby framework that lets you:
- **Define once** - Single semantic core for your domain
- **Project many** - Multiple API facets for different consumers
- **Zero duplication** - Auto-generated REST APIs
- **Guaranteed consistency** - All facets share core logic

---

## Getting Started

New to Facera? Start here:

1. **[Quick Start](../README.md#quick-start)** - Get up and running in 5 minutes
2. **[Core Concepts](Core-Concepts.md)** - Understand cores and facets
3. **[Examples](Examples.md)** - See complete working examples

---

## Documentation

### Fundamentals

Learn the core concepts and how to use them:

- **[Core Concepts](Core-Concepts.md)** - Understanding the facet model
  - What are cores and facets?
  - Why this architecture?
  - Design principles

- **[Defining Cores](Defining-Cores.md)** - Define your domain model
  - Entities and attributes
  - Capabilities (create, get, list, actions)
  - Invariants and business rules
  - Complete examples

- **[Defining Facets](Defining-Facets.md)** - Create consumer-specific views
  - Field visibility control
  - Capability access control
  - Computed fields
  - Error handling
  - Complete examples

### Features

Explore Facera's powerful features:

- **[API Generation](API-Generation.md)** - Auto-generated REST APIs
  - Generated endpoints
  - Request/response formats
  - HTTP status codes
  - Query parameters

- **[Auto-Mounting](Auto-Mounting.md)** - Zero-config discovery
  - Convention over configuration
  - Directory structure
  - Framework integration (Rails, Sinatra, Rack)
  - Startup process

- **[Configuration](Configuration.md)** - Customize your setup
  - Path configuration
  - Authentication strategies
  - Conditional facets
  - Feature flags
  - Environment-specific config

- **[Introspection](Introspection.md)** - Explore APIs at runtime
  - Introspection API endpoints
  - OpenAPI generation
  - Programmatic access
  - Use cases

### Advanced

Take your knowledge further:

- **[Examples](Examples.md)** - Complete working examples
  - Phase examples (01-04)
  - Runnable server
  - Testing examples
  - Real-world scenarios

- **[Deployment](Deployment.md)** - Production deployment
  - Web servers (Puma, Unicorn)
  - Docker & Docker Compose
  - Kubernetes
  - AWS, Heroku
  - Monitoring & security

- **[Architecture](Architecture.md)** - Internal design
  - Design principles
  - System architecture
  - Core components
  - Request flow
  - Extension points

### Contributing

Help make Facera better:

- **[Contributing](Contributing.md)** - Contribution guidelines
  - Development workflow
  - Code style
  - Testing requirements
  - Pull request process

---

## Quick Reference

### Common Tasks

**Define a core:**
```ruby
Facera.define_core(:payment) do
  entity :payment do
    attribute :amount, :money, required: true
  end

  capability :create_payment, type: :create do
    entity :payment
    requires :amount
  end
end
```

**Define a facet:**
```ruby
Facera.define_facet(:external, core: :payment) do
  expose :payment do
    fields :id, :amount, :status
  end
  allow_capabilities :create_payment
end
```

**Mount everything:**
```ruby
Rack::Builder.new do
  Facera.auto_mount!(self)
end
```

---

## Resources

### Links

- [GitHub Repository](https://github.com/yourusername/facera)
- [RubyGems Page](https://rubygems.org/gems/facera)
- [Issue Tracker](https://github.com/yourusername/facera/issues)
- [Discussions](https://github.com/yourusername/facera/discussions)

### External Documentation

- [Grape Framework](https://github.com/ruby-grape/grape) - API framework used by Facera
- [Rack](https://github.com/rack/rack) - Ruby web server interface
- [OpenAPI Specification](https://spec.openapis.org/oas/latest.html)

---

## Navigation by Topic

### I want to...

**Learn the basics:**
- [Understand what Facera is](Core-Concepts.md)
- [See working examples](Examples.md)
- [Get started quickly](../README.md#quick-start)

**Define my domain:**
- [Create entities and capabilities](Defining-Cores.md)
- [Add business rules and invariants](Defining-Cores.md#invariants)
- [Define state transitions](Defining-Cores.md#action-state-transitions)

**Create APIs:**
- [Define facets for different consumers](Defining-Facets.md)
- [Control field visibility](Defining-Facets.md#field-visibility)
- [Control capability access](Defining-Facets.md#capability-access-control)
- [Add computed fields](Defining-Facets.md#computed-fields)

**Configure my app:**
- [Set up authentication](Configuration.md#authentication)
- [Configure paths](Configuration.md#path-configuration)
- [Enable/disable features](Configuration.md#feature-flags)
- [Environment-specific config](Configuration.md#environment-specific-configuration)

**Deploy to production:**
- [Run with Puma/Unicorn](Deployment.md#web-servers)
- [Deploy with Docker](Deployment.md#docker)
- [Deploy to Kubernetes](Deployment.md#kubernetes)
- [Deploy to AWS/Heroku](Deployment.md#aws)

**Explore my APIs:**
- [Use introspection endpoints](Introspection.md#introspection-api)
- [Generate OpenAPI specs](Introspection.md#openapi-generation)
- [Inspect programmatically](Introspection.md#programmatic-introspection)

**Contribute:**
- [Set up development environment](Contributing.md#development-setup)
- [Submit a pull request](Contributing.md#pull-request-guidelines)
- [Report a bug](Contributing.md#areas-to-contribute)

---

## Support

Need help?

- 📚 Read the [documentation](#documentation)
- 💬 Ask in [Discussions](https://github.com/yourusername/facera/discussions)
- 🐛 Report bugs in [Issues](https://github.com/yourusername/facera/issues)
- 📧 Email: your-email@example.com

---

## License

Facera is released under the [MIT License](../LICENSE).

---

**One semantic core. Multiple API facets. Zero duplication.**

Happy building! 💎
