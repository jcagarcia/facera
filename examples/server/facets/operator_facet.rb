# Operator Facet
# Admin/support operator API with enhanced visibility
# Used by support tools and admin dashboards

Facera.define_facet(:operator, core: :payment) do
  description "Support operator and admin tools API"

  # Expose all fields plus additional operational data
  expose :payment do
    fields :all

    # Add operator-specific computed fields
    computed :customer_name do
      # In a real app: Customer.find(customer_id).name
      "Customer #{customer_id[0..7]}"
    end

    computed :merchant_name do
      # In a real app: Merchant.find(merchant_id).name
      "Merchant #{merchant_id[0..7]}"
    end

    computed :time_in_current_state do
      if status == :confirmed && confirmed_at
        Time.now - confirmed_at
      elsif status == :cancelled && cancelled_at
        Time.now - cancelled_at
      elsif created_at
        Time.now - created_at
      else
        0
      end
    end
  end

  # Allow all capabilities (operators can do everything)
  allow_capabilities :all

  # No scoping - operators need to see all payments for support
  # But we audit all their actions
  audit_all_operations user: :current_operator

  # Detailed errors for troubleshooting
  error_verbosity :detailed

  # Structured format for better tooling integration
  format :structured
end
