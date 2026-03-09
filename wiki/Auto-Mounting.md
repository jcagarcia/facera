# Auto-Mounting

Convention-based auto-discovery and mounting of cores and facets.

---

## Overview

Facera automatically discovers and mounts all cores and facets with **zero configuration**:

1. Discovers `.rb` files in conventional directories
2. Loads them in the correct order (cores first, then facets)
3. Generates REST APIs
4. Mounts them at configured paths

---

## Convention Over Configuration

### Standard Structure

```
your_app/
├── cores/
│   ├── payment_core.rb
│   └── user_core.rb
└── facets/
    ├── external_facet.rb
    ├── internal_facet.rb
    └── operator_facet.rb
```

### Rails Structure

```
your_app/
├── app/
│   ├── cores/
│   │   ├── payment_core.rb
│   │   └── user_core.rb
│   └── facets/
│       ├── external_facet.rb
│       ├── internal_facet.rb
│       └── operator_facet.rb
```

### Lib Structure

```
your_app/
├── lib/
│   ├── cores/
│   │   └── payment_core.rb
│   └── facets/
│       └── external_facet.rb
```

---

## Basic Usage

### Rack Application

```ruby
# config.ru
require 'facera'

Rack::Builder.new do
  use Rack::CommonLogger

  # Auto-discovers and mounts everything
  Facera.auto_mount!(self)
end
```

### With Middleware

```ruby
Rack::Builder.new do
  use Rack::Reloader, 0 if ENV['RACK_ENV'] == 'development'
  use Rack::CommonLogger
  use Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: [:get, :post, :put, :delete]
    end
  end

  Facera.auto_mount!(self)
end
```

### Rails Integration

```ruby
# config/application.rb
require 'facera'

# Facera automatically integrates via Railtie
# Cores and facets in app/cores/ and app/facets/ are auto-loaded
```

### Sinatra Integration

```ruby
require 'sinatra'
require 'facera'

Facera.auto_mount!(Sinatra::Application)

run Sinatra::Application
```

---

## Startup Logs

When `auto_mount!` runs, you'll see:

```
================================================================================
💎 Facera v0.1.0 - Auto-Mounting
================================================================================
📦 Loading cores...
  ✓ payment_core
  ✓ user_core
🎭 Loading facets...
  ✓ external_facet
  ✓ internal_facet
  ✓ operator_facet

📊 Found:
  Cores: 2
  Facets: 3

🚀 Mounting facets:
  ✓ external        → /api/v1                   (4 endpoints)
  ✓ internal        → /api/internal/v1          (8 endpoints)
  ✓ operator        → /api/operator/v1          (8 endpoints)

📚 Introspection API:
  ✓ Mounted at /api/facera
  • /api/facera/introspect - Full introspection
  • /api/facera/cores - All cores
  • /api/facera/facets - All facets
  • /api/facera/openapi - OpenAPI specs

================================================================================
✨ Facera ready! 3 facets mounted
================================================================================
```

---

## Discovery Process

### 1. Detect Load Paths

Facera looks for:
- Current directory (`Dir.pwd`)
- Parent directory
- `app/` subdirectory (Rails-style)
- `lib/` subdirectory

### 2. Find Core Files

Searches for `**/*.rb` in:
- `{base}/cores/`
- `{base}/app/cores/`
- `{base}/lib/cores/`

### 3. Find Facet Files

Searches for `**/*.rb` in:
- `{base}/facets/`
- `{base}/app/facets/`
- `{base}/lib/facets/`

### 4. Load in Order

1. Cores first (sorted alphabetically)
2. Facets second (sorted alphabetically)

### 5. Generate APIs

For each facet:
- Creates Grape::API class
- Generates endpoints based on capabilities
- Applies field visibility rules

### 6. Mount at Paths

Mounts each API at its configured path:
- External: `/api/v1`
- Internal: `/api/internal/v1`
- Operator: `/api/operator/v1`
- Introspection: `/api/facera`

---

## Configuration

### Basic Configuration

```ruby
Facera.configure do |config|
  config.base_path = '/api'
  config.version = 'v1'
end
```

### Custom Paths

```ruby
Facera.configure do |config|
  config.facet_path :external, '/v1'
  config.facet_path :internal, '/internal/v1'
  config.facet_path :operator, '/operator/v1'
end
```

### Disable Facets

```ruby
Facera.configure do |config|
  # Disable operator API in production
  config.disable_facet :operator unless ENV['ENABLE_OPERATOR_API']
end
```

---

## Manual Loading

If you need more control:

```ruby
# Load everything
Facera.load_all!

# Or load separately
Facera.load_cores!
Facera.load_facets!

# Custom load paths
Facera.load_all!(load_paths: ['/custom/path'])

# Then mount manually
Facera.auto_mount!(app)
```

---

## Framework Integration

### Pure Rack

```ruby
require 'facera'

run Rack::Builder.new {
  Facera.auto_mount!(self)
}
```

### Rails

```ruby
# Gemfile
gem 'facera'

# config/application.rb
require 'facera'

# That's it! Auto-loaded via Railtie
```

### Sinatra

```ruby
require 'sinatra'
require 'facera'

Facera.auto_mount!(Sinatra::Application)

run Sinatra::Application
```

### Custom Rack::Builder

```ruby
app = Rack::Builder.new do
  use SomeMiddleware

  # Auto-mount at root
  Facera.auto_mount!(self)

  # Or map to specific path
  map '/api' do
    Facera.auto_mount!(self)
  end
end

run app
```

---

## Example Application

### File Structure

```
payment_api/
├── cores/
│   └── payment_core.rb
├── facets/
│   ├── external_facet.rb
│   └── internal_facet.rb
├── config/
│   └── facera.rb
├── config.ru
└── Gemfile
```

### config/facera.rb

```ruby
Facera.configure do |config|
  config.base_path = '/api'
  config.version = 'v1'
  config.facet_path :external, '/v1'
  config.facet_path :internal, '/internal/v1'
end
```

### config.ru

```ruby
require 'facera'
require_relative 'config/facera'

app = Rack::Builder.new do
  use Rack::Reloader, 0 if ENV['RACK_ENV'] == 'development'
  use Rack::CommonLogger

  Facera.auto_mount!(self)
end

run app
```

### Run

```bash
rackup -p 9292
```

### Result

```
GET  /api/v1/health
POST /api/v1/payments
GET  /api/v1/payments/:id

GET  /api/internal/v1/health
POST /api/internal/v1/payments
GET  /api/internal/v1/payments/:id
POST /api/internal/v1/payments/:id/confirm

GET  /api/facera/introspect
GET  /api/facera/cores
GET  /api/facera/facets
GET  /api/facera/openapi
```

---

## Best Practices

### 1. Use Conventional Structure

```
✅ cores/ and facets/ at root
✅ app/cores/ and app/facets/ for Rails
❌ random_folder/cores/
```

### 2. One Definition Per File

```ruby
# ✅ cores/payment_core.rb
Facera.define_core(:payment) do
  # ...
end

# ❌ cores/all_cores.rb
Facera.define_core(:payment) { }
Facera.define_core(:user) { }
```

### 3. Name Files Consistently

```
✅ payment_core.rb -> define_core(:payment)
✅ external_facet.rb -> define_facet(:external)
❌ payment.rb -> define_core(:payment)
❌ api.rb -> define_facet(:external)
```

### 4. Configure Before Mounting

```ruby
# ✅ Good order
require 'facera'
require_relative 'config/facera'  # Configure
Facera.auto_mount!(self)          # Then mount

# ❌ Bad order
require 'facera'
Facera.auto_mount!(self)          # Mount
require_relative 'config/facera'  # Too late!
```

---

## Next Steps

- [Configuration](Configuration.md) - Authentication, paths, feature flags
- [Introspection](Introspection.md) - Explore mounted APIs at runtime
- [Examples](Examples.md) - Complete working examples
