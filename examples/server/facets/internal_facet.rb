# Internal Facet
# Service-to-service API for internal microservices
# Full access to all fields and operations

Facera.define_facet(:internal, core: :payment) do
  description "Internal service-to-service API"

  # Expose all fields for internal services
  expose :payment do
    fields :all

    # Add computed fields for internal use
    computed :age_in_seconds do
      created_at ? (Time.now - created_at).to_i : 0
    end

    computed :is_recent do
      age_in_seconds < 3600  # Less than 1 hour old
    end
  end

  # Allow all capabilities
  allow_capabilities :all

  # No scoping - internal services can see everything
  # They're trusted and may need to operate on any payment

  # Detailed errors for debugging
  error_verbosity :detailed

  # Audit all internal operations (in production, this would log to a service)
  audit_all_operations user: :system
end
