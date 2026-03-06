# Shared payment API definitions for server examples
require_relative '../../lib/facera'

# Define the payment core
Facera.define_core(:payment) do
  entity :payment do
    attribute :id, :uuid, immutable: true
    attribute :amount, :money, required: true
    attribute :currency, :string, required: true
    attribute :status, :enum, values: [:pending, :confirmed, :cancelled]
    attribute :merchant_id, :uuid, required: true
    attribute :customer_id, :uuid, required: true
    attribute :description, :string
    attribute :created_at, :timestamp
  end

  capability :create_payment, type: :create do
    entity :payment
    requires :amount, :currency, :merchant_id, :customer_id
    optional :description
  end

  capability :get_payment, type: :get do
    entity :payment
    requires :id
  end

  capability :list_payments, type: :list do
    entity :payment
    optional :limit, :offset, :merchant_id
    filterable :merchant_id
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
end

# Define the external facet (public API)
Facera.define_facet(:external, core: :payment) do
  description "Public API for external clients"

  expose :payment do
    fields :id, :amount, :currency, :status, :description, :created_at
  end

  allow_capabilities :create_payment, :get_payment, :list_payments

  error_verbosity :minimal
end

# Define the internal facet (service-to-service API)
Facera.define_facet(:internal, core: :payment) do
  description "Internal service API"

  expose :payment do
    fields :all
  end

  allow_capabilities :all

  error_verbosity :detailed
end
