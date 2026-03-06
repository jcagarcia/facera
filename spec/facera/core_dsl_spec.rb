RSpec.describe "Core DSL" do
  before do
    Facera::Registry.reset!
  end

  describe "defining a core" do
    it "creates a core with a name" do
      core = Facera.define_core(:payment) do
      end

      expect(core).to be_a(Facera::Core)
      expect(core.name).to eq(:payment)
    end

    it "registers the core in the registry" do
      Facera.define_core(:payment) do
      end

      expect(Facera.cores).to have_key(:payment)
    end
  end

  describe "defining entities" do
    it "creates an entity within a core" do
      core = Facera.define_core(:payment) do
        entity :payment do
          attribute :id, :uuid, immutable: true
          attribute :amount, :money, required: true
        end
      end

      expect(core.entities).to have_key(:payment)
      entity = core.entities[:payment]
      expect(entity.attributes).to have_key(:id)
      expect(entity.attributes).to have_key(:amount)
    end

    it "validates attribute types" do
      expect {
        Facera.define_core(:payment) do
          entity :payment do
            attribute :id, :invalid_type
          end
        end
      }.to raise_error(Facera::Error, /Invalid attribute type/)
    end

    it "supports enum attributes with values" do
      core = Facera.define_core(:payment) do
        entity :payment do
          attribute :status, :enum, values: [:pending, :confirmed, :cancelled]
        end
      end

      attr = core.entities[:payment].attributes[:status]
      expect(attr.enum_values).to eq([:pending, :confirmed, :cancelled])
    end

    it "requires values for enum attributes" do
      expect {
        Facera.define_core(:payment) do
          entity :payment do
            attribute :status, :enum
          end
        end
      }.to raise_error(Facera::Error, /must specify :values/)
    end
  end

  describe "defining capabilities" do
    it "creates capabilities with required params" do
      core = Facera.define_core(:payment) do
        capability :create_payment, type: :create do
          entity :payment
          requires :amount, :currency
          optional :description
        end
      end

      capability = core.capabilities[:create_payment]
      expect(capability.type).to eq(:create)
      expect(capability.required_params).to include(:amount, :currency)
      expect(capability.optional_params).to include(:description)
    end

    it "validates capability types" do
      expect {
        Facera.define_core(:payment) do
          capability :do_something, type: :invalid
        end
      }.to raise_error(Facera::Error, /Invalid capability type/)
    end

    it "supports preconditions" do
      core = Facera.define_core(:payment) do
        capability :confirm_payment, type: :action do
          requires :id
          precondition { status == :pending }
        end
      end

      capability = core.capabilities[:confirm_payment]
      expect(capability.preconditions).not_to be_empty
    end

    it "supports validations" do
      core = Facera.define_core(:payment) do
        capability :create_payment, type: :create do
          requires :amount
          validates { amount > 0 }
        end
      end

      capability = core.capabilities[:create_payment]
      expect(capability.validations).not_to be_empty
    end

    it "supports state transitions" do
      core = Facera.define_core(:payment) do
        capability :confirm_payment, type: :action do
          transitions_to :confirmed
        end
      end

      capability = core.capabilities[:confirm_payment]
      expect(capability.transitions).to include(:confirmed)
    end

    it "supports field setters" do
      core = Facera.define_core(:payment) do
        capability :confirm_payment, type: :action do
          sets confirmed_at: -> { Time.now }
        end
      end

      capability = core.capabilities[:confirm_payment]
      expect(capability.field_setters).to have_key(:confirmed_at)
    end
  end

  describe "defining invariants" do
    it "creates invariants with validation blocks" do
      core = Facera.define_core(:payment) do
        entity :payment do
          attribute :amount, :money
        end

        invariant :positive_amount do
          amount > 0
        end
      end

      expect(core.invariants).to have_key(:positive_amount)
    end

    it "requires a block for invariants" do
      expect {
        Facera.define_core(:payment) do
          invariant :positive_amount
        end
      }.to raise_error(Facera::Error, /must have a block/)
    end
  end

  describe "complete example" do
    it "defines a complete payment core" do
      core = Facera.define_core(:payment) do
        entity :payment do
          attribute :id, :uuid, immutable: true
          attribute :amount, :money, required: true
          attribute :currency, :string, required: true
          attribute :status, :enum, values: [:pending, :confirmed, :cancelled]
          attribute :merchant_id, :uuid, required: true
          attribute :customer_id, :uuid, required: true
          attribute :description, :string
          attribute :metadata, :hash
          attribute :created_at, :timestamp, immutable: true
          attribute :confirmed_at, :timestamp
        end

        invariant :positive_amount do
          amount > 0
        end

        invariant :valid_status_transitions do
          case status
          when :pending then [:confirmed, :cancelled]
          when :confirmed then []
          else []
          end
        end

        capability :create_payment, type: :create do
          entity :payment
          requires :amount, :currency, :merchant_id, :customer_id
          optional :description, :metadata

          validates do
            amount > 0
          end
        end

        capability :confirm_payment, type: :action do
          entity :payment
          requires :id
          optional :confirmation_code

          precondition { status == :pending }
          transitions_to :confirmed
          sets confirmed_at: -> { Time.now }
        end

        capability :get_payment, type: :get do
          entity :payment
          requires :id
          returns :payment
        end

        capability :list_payments, type: :list do
          entity :payment
          optional :merchant_id, :customer_id, :status, :limit, :offset
          filterable :merchant_id, :customer_id, :status
          returns :collection
        end
      end

      expect(core.entities.count).to eq(1)
      expect(core.capabilities.count).to eq(4)
      expect(core.invariants.count).to eq(2)

      # Verify entity
      payment_entity = core.find_entity(:payment)
      expect(payment_entity.attributes.count).to eq(10)
      expect(payment_entity.required_attributes.map(&:name)).to include(:amount, :currency, :merchant_id, :customer_id)
      expect(payment_entity.immutable_attributes.map(&:name)).to include(:id, :created_at)

      # Verify capabilities
      create_cap = core.find_capability(:create_payment)
      expect(create_cap.type).to eq(:create)
      expect(create_cap.required_params).to include(:amount, :currency)

      confirm_cap = core.find_capability(:confirm_payment)
      expect(confirm_cap.type).to eq(:action)
      expect(confirm_cap.preconditions).not_to be_empty
      expect(confirm_cap.transitions).to include(:confirmed)

      list_cap = core.find_capability(:list_payments)
      expect(list_cap.type).to eq(:list)
      expect(list_cap.filterable_params).to include(:merchant_id, :customer_id, :status)
    end
  end
end
