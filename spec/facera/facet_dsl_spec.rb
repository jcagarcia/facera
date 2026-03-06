RSpec.describe "Facet DSL" do
  before do
    Facera::Registry.reset!

    # Define a payment core for testing
    Facera.define_core(:payment) do
      entity :payment do
        attribute :id, :uuid, immutable: true
        attribute :amount, :money, required: true
        attribute :currency, :string, required: true
        attribute :status, :enum, values: [:pending, :confirmed, :cancelled]
        attribute :merchant_id, :uuid, required: true
        attribute :customer_id, :uuid, required: true
        attribute :description, :string
        attribute :metadata, :hash
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
        filterable :merchant_id, :customer_id
      end

      capability :confirm_payment, type: :action do
        entity :payment
        requires :id
      end

      capability :cancel_payment, type: :action do
        entity :payment
        requires :id
      end
    end
  end

  describe "defining a facet" do
    it "creates a facet with a name and core reference" do
      facet = Facera.define_facet(:external, core: :payment) do
      end

      expect(facet).to be_a(Facera::Facet)
      expect(facet.name).to eq(:external)
      expect(facet.core_name).to eq(:payment)
    end

    it "registers the facet in the registry" do
      Facera.define_facet(:external, core: :payment) do
      end

      expect(Facera.facets).to have_key(:external)
    end

    it "can access the core" do
      facet = Facera.define_facet(:external, core: :payment) do
      end

      expect(facet.core).to be_a(Facera::Core)
      expect(facet.core.name).to eq(:payment)
    end

    it "supports description" do
      facet = Facera.define_facet(:external, core: :payment) do
        description "Public API for external clients"
      end

      expect(facet.description).to eq("Public API for external clients")
    end
  end

  describe "field visibility control" do
    it "exposes specific fields" do
      facet = Facera.define_facet(:external, core: :payment) do
        expose :payment do
          fields :id, :amount, :currency, :status
        end
      end

      visibility = facet.field_visibility_for(:payment)
      expect(visibility.visible?(:id)).to be true
      expect(visibility.visible?(:amount)).to be true
      expect(visibility.visible?(:merchant_id)).to be false
    end

    it "exposes all fields by default" do
      facet = Facera.define_facet(:internal, core: :payment) do
        expose :payment do
          fields :all
        end
      end

      visibility = facet.field_visibility_for(:payment)
      expect(visibility.visible?(:id)).to be true
      expect(visibility.visible?(:merchant_id)).to be true
      expect(visibility.visible?(:metadata)).to be true
    end

    it "hides specific fields" do
      facet = Facera.define_facet(:external, core: :payment) do
        expose :payment do
          fields :all
          hide :merchant_id, :metadata
        end
      end

      visibility = facet.field_visibility_for(:payment)
      expect(visibility.visible?(:id)).to be true
      expect(visibility.visible?(:merchant_id)).to be false
      expect(visibility.visible?(:metadata)).to be false
    end

    it "supports field aliasing" do
      facet = Facera.define_facet(:external, core: :payment) do
        expose :payment do
          fields :created_at
          alias_field :created_at, as: :createdAt
        end
      end

      visibility = facet.field_visibility_for(:payment)
      expect(visibility.aliased_name(:created_at)).to eq(:createdAt)
    end

    it "supports computed fields" do
      facet = Facera.define_facet(:operator, core: :payment) do
        expose :payment do
          computed :customer_name do
            "John Doe"
          end
        end
      end

      visibility = facet.field_visibility_for(:payment)
      expect(visibility.computed_fields).to have_key(:customer_name)
      expect(visibility.computed_fields[:customer_name]).to be_a(Proc)
    end

    it "requires a block for computed fields" do
      expect {
        Facera.define_facet(:operator, core: :payment) do
          expose :payment do
            computed :customer_name
          end
        end
      }.to raise_error(Facera::Error, /must have a block/)
    end
  end

  describe "capability access control" do
    it "allows specific capabilities" do
      facet = Facera.define_facet(:external, core: :payment) do
        allow_capabilities :create_payment, :get_payment, :list_payments
      end

      expect(facet.capability_allowed?(:create_payment)).to be true
      expect(facet.capability_allowed?(:get_payment)).to be true
      expect(facet.capability_allowed?(:cancel_payment)).to be false
    end

    it "allows all capabilities by default" do
      facet = Facera.define_facet(:internal, core: :payment) do
        allow_capabilities :all
      end

      expect(facet.capability_allowed?(:create_payment)).to be true
      expect(facet.capability_allowed?(:cancel_payment)).to be true
    end

    it "denies specific capabilities" do
      facet = Facera.define_facet(:external, core: :payment) do
        allow_capabilities :all
        deny_capabilities :cancel_payment, :confirm_payment
      end

      expect(facet.capability_allowed?(:create_payment)).to be true
      expect(facet.capability_allowed?(:cancel_payment)).to be false
      expect(facet.capability_allowed?(:confirm_payment)).to be false
    end

    it "returns allowed capability names" do
      facet = Facera.define_facet(:external, core: :payment) do
        allow_capabilities :create_payment, :get_payment
      end

      allowed = facet.allowed_capabilities
      expect(allowed).to include(:create_payment, :get_payment)
      expect(allowed).not_to include(:cancel_payment)
    end
  end

  describe "capability scoping" do
    it "defines scopes for capabilities" do
      facet = Facera.define_facet(:external, core: :payment) do
        scope :list_payments do
          { customer_id: "current_customer_id" }
        end
      end

      expect(facet.has_scope_for?(:list_payments)).to be true
      expect(facet.capability_scope(:list_payments)).to be_a(Proc)
    end

    it "requires a block for scopes" do
      expect {
        Facera.define_facet(:external, core: :payment) do
          scope :list_payments
        end
      }.to raise_error(Facera::Error, /must have a block/)
    end
  end

  describe "error handling" do
    it "sets error verbosity level" do
      facet = Facera.define_facet(:external, core: :payment) do
        error_verbosity :minimal
      end

      expect(facet.error_verbosity).to eq(:minimal)
    end

    it "defaults to minimal verbosity" do
      facet = Facera.define_facet(:external, core: :payment) do
      end

      expect(facet.error_verbosity).to eq(:minimal)
    end

    it "formats errors according to verbosity" do
      facet = Facera.define_facet(:external, core: :payment) do
        error_verbosity :minimal
      end

      error = Facera::ValidationError.new(["amount is required"])
      formatted = facet.format_error(error)

      expect(formatted).to have_key(:error)
      expect(formatted).to have_key(:message)
    end
  end

  describe "additional facet options" do
    it "sets format type" do
      facet = Facera.define_facet(:agent, core: :payment) do
        format :structured
      end

      expect(facet.format).to eq(:structured)
    end

    it "sets rate limiting" do
      facet = Facera.define_facet(:agent, core: :payment) do
        rate_limit requests: 1000, per: :minute
      end

      expect(facet.rate_limit).to eq({ requests: 1000, per: :minute })
    end

    it "enables audit logging" do
      facet = Facera.define_facet(:operator, core: :payment) do
        audit_all_operations user: :current_operator
      end

      expect(facet.audit_enabled).to be true
    end
  end

  describe "complete facet example" do
    it "defines a complete external facet" do
      facet = Facera.define_facet(:external, core: :payment) do
        description "Public API for external clients"

        expose :payment do
          fields :id, :amount, :currency, :status, :description, :created_at
          hide :merchant_id, :metadata
          alias_field :created_at, as: :createdAt
        end

        allow_capabilities :create_payment, :get_payment, :list_payments
        deny_capabilities :cancel_payment, :confirm_payment

        scope :list_payments do
          { customer_id: "current_customer_id" }
        end

        error_verbosity :minimal
      end

      expect(facet.name).to eq(:external)
      expect(facet.description).to eq("Public API for external clients")
      expect(facet.error_verbosity).to eq(:minimal)

      # Field visibility
      visibility = facet.field_visibility_for(:payment)
      expect(visibility.visible?(:id)).to be true
      expect(visibility.visible?(:merchant_id)).to be false
      expect(visibility.aliased_name(:created_at)).to eq(:createdAt)

      # Capability access
      expect(facet.capability_allowed?(:create_payment)).to be true
      expect(facet.capability_allowed?(:cancel_payment)).to be false

      # Scoping
      expect(facet.has_scope_for?(:list_payments)).to be true
    end

    it "defines a complete internal facet" do
      facet = Facera.define_facet(:internal, core: :payment) do
        description "Service-to-service API"

        expose :payment do
          fields :all
        end

        allow_capabilities :all

        error_verbosity :detailed
      end

      expect(facet.description).to eq("Service-to-service API")
      expect(facet.error_verbosity).to eq(:detailed)

      visibility = facet.field_visibility_for(:payment)
      expect(visibility.visible?(:id)).to be true
      expect(visibility.visible?(:merchant_id)).to be true
      expect(visibility.visible?(:metadata)).to be true

      expect(facet.capability_allowed?(:create_payment)).to be true
      expect(facet.capability_allowed?(:cancel_payment)).to be true
    end

    it "defines a complete operator facet" do
      facet = Facera.define_facet(:operator, core: :payment) do
        description "Support operator tools"

        expose :payment do
          fields :all
          computed :customer_name do
            "Customer Name"
          end
        end

        allow_capabilities :all
        audit_all_operations user: :current_operator

        error_verbosity :detailed
      end

      expect(facet.description).to eq("Support operator tools")
      expect(facet.audit_enabled).to be true

      visibility = facet.field_visibility_for(:payment)
      expect(visibility.computed_fields).to have_key(:customer_name)
    end
  end
end
