# Payment Facets
# All audience-specific facets for the payment core.
#
# Facet names are the audience name only. Paths are auto-derived as /{audience}/{version}:
#
#   public   -> /public/v1    (with /payments resource)
#   internal -> /internal/v1  (with /payments resource)
#   ops      -> /ops/v1       (with /payments resource)
#
# Facets sharing the same audience name across cores are grouped into one API:
#   public (payment) + public (refund) -> /public/v1 with /payments and /refunds

# Public Facet — customer-facing API with limited field exposure
Facera.define_facet(:public, core: :payment) do
  description "Customer-facing payments API"

  expose :payment do
    fields :id, :amount, :currency, :status, :description, :created_at

    alias_field :created_at, as: :createdAt
  end

  allow_capabilities :create_payment, :get_payment, :list_payments
  deny_capabilities :confirm_payment, :cancel_payment

  scope :list_payments do
    # { customer_id: current_user.id }
    {}
  end

  error_verbosity :minimal
  rate_limit requests: 1000, per: :hour
end

# Internal Facet — service-to-service API with full field access
Facera.define_facet(:internal, core: :payment) do
  description "Internal service-to-service payments API"

  expose :payment do
    fields :all

    computed :age_in_seconds do
      created_at ? (Time.now - created_at).to_i : 0
    end

    computed :is_recent do
      age_in_seconds < 3600
    end
  end

  allow_capabilities :all

  error_verbosity :detailed
  audit_all_operations user: :system
end

# Ops Facet — operator and support agent API
# Groups with ops (refund) -> /ops/v1 with /payments and /refunds
Facera.define_facet(:ops, core: :payment) do
  description "Operator and support agent payments API"

  expose :payment do
    fields :all

    computed :customer_display do
      "Customer #{customer_id[0..7]}"
    end

    computed :merchant_display do
      "Merchant #{merchant_id[0..7]}"
    end

    computed :time_in_current_state do
      if status == :confirmed && confirmed_at
        (Time.now - confirmed_at).to_i
      elsif status == :cancelled && cancelled_at
        (Time.now - cancelled_at).to_i
      elsif created_at
        (Time.now - created_at).to_i
      else
        0
      end
    end
  end

  allow_capabilities :all

  audit_all_operations user: :current_agent
  error_verbosity :detailed
  format :structured
end
