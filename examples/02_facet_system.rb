require_relative '../lib/facera'

# Define the payment core
Facera.define_core(:payment) do
  entity :payment do
    attribute :id, :uuid, immutable: true
    attribute :amount, :money, required: true
    attribute :currency, :string, required: true
    attribute :status, :enum, values: [:pending, :confirmed, :cancelled, :refunded]
    attribute :merchant_id, :uuid, required: true
    attribute :customer_id, :uuid, required: true
    attribute :description, :string
    attribute :metadata, :hash
    attribute :created_at, :timestamp, immutable: true
    attribute :confirmed_at, :timestamp
    attribute :cancelled_at, :timestamp
  end

  invariant :positive_amount do
    amount > 0
  end

  capability :create_payment, type: :create do
    entity :payment
    requires :amount, :currency, :merchant_id, :customer_id
    optional :description, :metadata
  end

  capability :get_payment, type: :get do
    entity :payment
    requires :id
  end

  capability :list_payments, type: :list do
    entity :payment
    optional :merchant_id, :customer_id, :status
    filterable :merchant_id, :customer_id, :status
  end

  capability :confirm_payment, type: :action do
    entity :payment
    requires :id
    precondition { status == :pending }
    transitions_to :confirmed
  end

  capability :cancel_payment, type: :action do
    entity :payment
    requires :id
    precondition { status == :pending }
    transitions_to :cancelled
  end

  capability :refund_payment, type: :action do
    entity :payment
    requires :id
    precondition { status == :confirmed }
    transitions_to :refunded
  end
end

# Define the external facet (for public API)
external_facet = Facera.define_facet(:external, core: :payment) do
  description "Public API for external clients"

  expose :payment do
    fields :id, :amount, :currency, :status, :description, :created_at
    hide :merchant_id, :metadata
    alias_field :created_at, as: :createdAt
  end

  allow_capabilities :create_payment, :get_payment, :list_payments
  deny_capabilities :cancel_payment, :refund_payment

  scope :list_payments do
    { customer_id: "current_customer_id" }
  end

  error_verbosity :minimal
end

# Define the internal facet (for service-to-service)
internal_facet = Facera.define_facet(:internal, core: :payment) do
  description "Service-to-service API"

  expose :payment do
    fields :all
  end

  allow_capabilities :all

  error_verbosity :detailed
end

# Define the operator facet (for support tools)
operator_facet = Facera.define_facet(:operator, core: :payment) do
  description "Support operator tools"

  expose :payment do
    fields :all

    computed :customer_name do
      "Customer #{customer_id}"
    end

    computed :risk_score do
      42
    end
  end

  allow_capabilities :all
  audit_all_operations user: :current_operator

  error_verbosity :detailed
end

# Define the agent facet (for automated systems)
agent_facet = Facera.define_facet(:agent, core: :payment) do
  description "Automated agent API with structured responses"

  expose :payment do
    fields :all
  end

  allow_capabilities :create_payment, :confirm_payment, :get_payment

  rate_limit requests: 1000, per: :minute

  format :structured
  error_verbosity :structured
end

# Display facet comparison
puts "=" * 80
puts "Payment System - Multi-Facet API"
puts "=" * 80
puts

core = Facera.find_core(:payment)
puts "Core: #{core.name}"
puts "  Entities: #{core.entities.count}"
puts "  Capabilities: #{core.capabilities.count}"
puts "  Invariants: #{core.invariants.count}"
puts

facets = [external_facet, internal_facet, operator_facet, agent_facet]

puts "Facets Comparison:"
puts "-" * 80
puts sprintf("%-15s %-30s %-12s %s", "Facet", "Description", "Verbosity", "Capabilities")
puts "-" * 80

facets.each do |facet|
  puts sprintf("%-15s %-30s %-12s %d/%d",
    facet.name,
    facet.description.to_s[0..28],
    facet.error_verbosity,
    facet.allowed_capabilities.count,
    core.capabilities.count
  )
end

puts
puts "-" * 80
puts "Field Visibility Matrix:"
puts "-" * 80

entity = core.find_entity(:payment)
fields = entity.attributes.keys

puts sprintf("%-20s %s", "Field", facets.map(&:name).map { |n| sprintf("%-10s", n) }.join(" "))
puts "-" * 80

fields.each do |field|
  visibility = facets.map do |facet|
    vis = facet.field_visibility_for(:payment)
    vis && vis.visible?(field) ? "✓" : "✗"
  end
  puts sprintf("%-20s %s", field, visibility.map { |v| sprintf("%-10s", v) }.join(" "))
end

puts
puts "-" * 80
puts "Capability Access Matrix:"
puts "-" * 80

capabilities = core.capabilities.keys
puts sprintf("%-20s %s", "Capability", facets.map(&:name).map { |n| sprintf("%-10s", n) }.join(" "))
puts "-" * 80

capabilities.each do |cap|
  access = facets.map do |facet|
    facet.capability_allowed?(cap) ? "✓" : "✗"
  end
  puts sprintf("%-20s %s", cap, access.map { |a| sprintf("%-10s", a) }.join(" "))
end

puts
puts "-" * 80
puts "Additional Features:"
puts "-" * 80

facets.each do |facet|
  features = []
  features << "Scoping" if facet.has_scope_for?(:list_payments)
  features << "Rate Limiting" if facet.rate_limit
  features << "Audit Logging" if facet.audit_enabled
  features << "Computed Fields" if facet.field_visibility_for(:payment)&.computed_fields&.any?

  puts "#{facet.name}: #{features.any? ? features.join(', ') : 'None'}"
end

puts
puts "=" * 80
puts "All facets successfully defined!"
puts "=" * 80
