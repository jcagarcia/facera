#!/usr/bin/env ruby
require_relative '../lib/facera'

puts "=" * 80
puts "Example 05: Adapters & Business Logic Implementation"
puts "=" * 80

# Example 1: Inline execution blocks (for simple logic)
puts "\n📝 Example 1: Inline execution blocks"
puts "-" * 80

Facera.define_core(:simple_counter) do
  entity :counter do
    attribute :id, :uuid
    attribute :count, :integer
  end

  capability :increment_counter, type: :action do
    entity :counter
    requires :id

    # Simple inline implementation
    execute do |params|
      {
        id: params[:id],
        count: 42,  # In reality, fetch and increment
        incremented_at: Time.now
      }
    end
  end
end

counter_core = Facera::Registry.cores[:simple_counter]
puts "✓ Core defined: #{counter_core.name}"
puts "✓ Capability with execute block: #{counter_core.capabilities.keys.first}"

# Example 2: Adapter pattern (for complex logic)
puts "\n🔌 Example 2: Adapter pattern"
puts "-" * 80

# Define the core
Facera.define_core(:blog) do
  entity :post do
    attribute :id, :uuid
    attribute :title, :string, required: true
    attribute :content, :string
    attribute :status, :enum, values: [:draft, :published]
    attribute :published_at, :datetime
  end

  capability :create_post, type: :create do
    entity :post
    requires :title, :content
  end

  capability :publish_post, type: :action do
    entity :post
    requires :id
    precondition { status == :draft }
    transitions_to :published
    sets published_at: -> { Time.now }
  end
end

# Implement the adapter
class BlogAdapter
  include Facera::Adapter

  @@posts = {}

  def create_post(params)
    post = {
      id: SecureRandom.uuid,
      title: params[:title],
      content: params[:content],
      status: :draft,
      created_at: Time.now
    }

    @@posts[post[:id]] = post

    puts "  💾 Created post: #{post[:title]}"
    post
  end

  def get_post(params)
    @@posts[params[:id]]
  end

  def publish_post(params)
    post = get_post(params)

    # Do the actual publishing
    post[:status] = :published
    post[:published_at] = Time.now

    # In production, you might:
    # - Clear cache
    # - Update search index
    # - Send notifications
    # - Trigger webhooks

    puts "  📢 Published post: #{post[:title]}"
    post
  end
end

# Register the adapter
Facera::AdapterRegistry.register(:blog, BlogAdapter)

blog_core = Facera::Registry.cores[:blog]
puts "✓ Core defined: #{blog_core.name}"
puts "✓ Adapter registered: BlogAdapter"

# Example 3: Using both approaches
puts "\n🎭 Example 3: Mixed approach (adapter + inline blocks)"
puts "-" * 80

Facera.define_core(:product) do
  entity :product do
    attribute :id, :uuid
    attribute :name, :string
    attribute :price, :money
    attribute :stock, :integer
  end

  # Complex operation - use adapter
  capability :create_product, type: :create do
    entity :product
    requires :name, :price
  end

  # Simple operation - use inline block
  capability :check_stock, type: :action do
    entity :product
    requires :id

    execute do |params|
      # Simple stock check
      {
        id: params[:id],
        stock: 10,
        available: true
      }
    end
  end
end

class ProductAdapter
  include Facera::Adapter

  def create_product(params)
    {
      id: SecureRandom.uuid,
      name: params[:name],
      price: params[:price],
      stock: 0,
      created_at: Time.now
    }
  end
end

Facera::AdapterRegistry.register(:product, ProductAdapter)

product_core = Facera::Registry.cores[:product]
puts "✓ Core defined: #{product_core.name}"
puts "  - create_product: uses ProductAdapter"
puts "  - check_stock: uses inline execute block"

# Summary
puts "\n" + "=" * 80
puts "✨ Summary"
puts "=" * 80
puts "
Facera supports two implementation patterns:

1. 📝 Inline Blocks - For simple, one-off logic
   capability :action do
     execute do |params|
       # Simple logic here
     end
   end

2. 🔌 Adapter Pattern - For complex, testable business logic
   class MyAdapter
     include Facera::Adapter

     def capability_name(params)
       # Complex logic here
     end
   end

Choose the right tool for the job!
"

puts "=" * 80
