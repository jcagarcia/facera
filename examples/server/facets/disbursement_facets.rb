# Disbursement Facets
# Disbursements are an internal operations concern — only exposed to the ops audience.
#
# ops -> /ops/api/v1 (with /disbursements resource, grouped with payment + refund)

Facera.define_facet(:ops, core: :disbursement) do
  description "Operator disbursement management API"

  expose :disbursement do
    fields :all

    computed :recipient_display do
      "Recipient #{recipient_id[0..7]}"
    end

    computed :merchant_display do
      "Merchant #{merchant_id[0..7]}"
    end

    computed :age_in_seconds do
      created_at ? (Time.now - created_at).to_i : 0
    end
  end

  allow_capabilities :all

  audit_all_operations user: :current_agent
  error_verbosity :detailed
end
