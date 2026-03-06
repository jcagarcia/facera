# External Facet
# Public-facing API for external clients
# Exposes limited fields and capabilities for security

Facera.define_facet(:external, core: :payment) do
  description "Public API for external clients"

  # Expose only safe fields to external consumers
  expose :payment do
    fields :id, :amount, :currency, :status, :description, :created_at

    # Hide sensitive internal fields
    hide :merchant_id, :customer_id, :metadata, :confirmed_at, :cancelled_at

    # Use camelCase for external API (common in JavaScript/TypeScript clients)
    alias_field :created_at, as: :createdAt
  end

  # Limit capabilities to read operations and creation
  allow_capabilities :create_payment, :get_payment, :list_payments

  # Explicitly deny admin operations
  deny_capabilities :confirm_payment, :cancel_payment

  # Scope list operations to current customer
  # In a real app, this would use authentication context
  scope :list_payments do
    # This would be: { customer_id: current_user.id }
    # For demo purposes, we'll just pass through
    {}
  end

  # Minimal error messages for security
  error_verbosity :minimal

  # Optional: Rate limiting configuration
  rate_limit requests: 1000, per: :hour
end
