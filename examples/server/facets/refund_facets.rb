# Refund Facets
# All audience-specific facets for the refund core.
#
# Facet names are the audience name only. Paths are auto-derived as /{audience}/{version}:
#
#   public   -> /public/v1    (merged with payment's public facet -> /refunds resource)
#   internal -> /internal/v1  (merged with payment's internal facet -> /refunds resource)
#   ops      -> /ops/v1       (merged with payment's ops facet -> /refunds resource)

# Public Facet — customer-facing API, merged with public (payment) under /public/v1
Facera.define_facet(:public, core: :refund) do
  description "Customer-facing refund request and tracking API"

  expose :refund do
    fields :id, :payment_id, :amount, :currency, :status, :reason, :created_at

    hide :customer_id, :notes, :rejection_reason, :approved_at, :rejected_at, :processed_at

    alias_field :created_at, as: :createdAt
  end

  allow_capabilities :create_refund, :get_refund, :list_refunds
  deny_capabilities :approve_refund, :reject_refund, :process_refund

  scope :list_refunds do
    # { customer_id: current_user.id }
    {}
  end

  error_verbosity :minimal
  rate_limit requests: 1000, per: :hour
end

# Ops Facet — operator API, merged with ops (payment) under /ops/v1
Facera.define_facet(:ops, core: :refund) do
  description "Operator and support agent refunds API"

  expose :refund do
    fields :all

    computed :customer_display do
      "Customer #{customer_id[0..7]}"
    end

    computed :linked_payment do
      "Payment #{payment_id[0..7]}"
    end

    computed :days_pending do
      status == :pending && created_at ? ((Time.now - created_at) / 86400.0).round(1) : 0
    end
  end

  # Operators can review and action refunds but cannot create them on behalf of customers
  allow_capabilities :all
  deny_capabilities :create_refund

  audit_all_operations user: :current_agent
  error_verbosity :detailed
  format :structured
end

# Internal Facet — service-to-service API, merged with internal (payment) under /internal/v1
Facera.define_facet(:internal, core: :refund) do
  description "Internal service-to-service refunds API"

  expose :refund do
    fields :all

    computed :age_in_seconds do
      created_at ? (Time.now - created_at).to_i : 0
    end

    computed :days_pending do
      status == :pending ? (age_in_seconds / 86400.0).round(1) : 0
    end
  end

  allow_capabilities :all

  error_verbosity :detailed
  audit_all_operations user: :system
end
