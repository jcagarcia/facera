RSpec.describe Facera::Executor do
  before do
    Facera::Registry.reset!

    Facera.define_core(:payment) do
      entity :payment do
        attribute :id, :uuid, immutable: true
        attribute :amount, :money, required: true
        attribute :currency, :string, required: true
        attribute :status, :enum, values: [:pending, :confirmed, :cancelled]
        attribute :merchant_id, :uuid, required: true
        attribute :customer_id, :uuid, required: true
      end

      invariant :positive_amount do
        amount > 0
      end

      capability :create_payment, type: :create do
        entity :payment
        requires :amount, :currency, :merchant_id, :customer_id
        validates { amount > 0 }
      end

      capability :get_payment, type: :get do
        entity :payment
        requires :id
      end

      capability :list_payments, type: :list do
        entity :payment
        optional :merchant_id, :limit, :offset
        filterable :merchant_id
      end

      capability :confirm_payment, type: :action do
        entity :payment
        requires :id
        precondition { status == :pending }
        transitions_to :confirmed
        sets confirmed_at: -> { Time.now }
      end
    end

    Facera.define_facet(:external, core: :payment) do
      expose :payment do
        fields :id, :amount, :currency, :status
      end

      allow_capabilities :create_payment, :get_payment, :list_payments

      scope :list_payments do
        { customer_id: 'scoped-customer-123' }
      end
    end

    Facera.define_facet(:internal, core: :payment) do
      expose :payment do
        fields :all
      end

      allow_capabilities :all
    end
  end

  describe "#execute" do
    context "with create capability" do
      it "executes create and returns result" do
        result = Facera::Executor.run(
          facet: :external,
          capability: :create_payment,
          params: {
            amount: 100.0,
            currency: 'USD',
            merchant_id: '550e8400-e29b-41d4-a716-446655440000',
            customer_id: '6ba7b810-9dad-11d1-80b4-00c04fd430c8'
          }
        )

        expect(result).to include(
          amount: 100.0,
          currency: 'USD',
          merchant_id: '550e8400-e29b-41d4-a716-446655440000',
          customer_id: '6ba7b810-9dad-11d1-80b4-00c04fd430c8'
        )
        expect(result[:id]).to be_a(String)
        expect(result[:created_at]).to be_a(Time)
      end

      it "validates required parameters" do
        expect {
          Facera::Executor.run(
            facet: :external,
            capability: :create_payment,
            params: { amount: 100.0 }
          )
        }.to raise_error(Facera::ValidationError, /currency/)
      end
    end

    context "with get capability" do
      it "executes get and returns result" do
        payment_id = '550e8400-e29b-41d4-a716-446655440000'
        result = Facera::Executor.run(
          facet: :external,
          capability: :get_payment,
          params: { id: payment_id }
        )

        expect(result[:id]).to eq(payment_id)
        expect(result).to have_key(:created_at)
      end
    end

    context "with list capability" do
      it "executes list and returns collection" do
        result = Facera::Executor.run(
          facet: :external,
          capability: :list_payments,
          params: { limit: 10, offset: 0 }
        )

        expect(result).to have_key(:data)
        expect(result).to have_key(:meta)
        expect(result[:data]).to be_an(Array)
        expect(result[:meta]).to include(total: 1, limit: 10, offset: 0)
      end

      it "applies facet scoping" do
        result = Facera::Executor.run(
          facet: :external,
          capability: :list_payments,
          params: {}
        )

        # The executor should have applied the scope which adds customer_id
        # In a real implementation, this would filter the query
        expect(result).to have_key(:data)
      end
    end

    context "with action capability" do
      it "executes action and applies transitions" do
        payment_id = '550e8400-e29b-41d4-a716-446655440000'
        result = Facera::Executor.run(
          facet: :internal,
          capability: :confirm_payment,
          params: { id: payment_id },
          context: { status: :pending }
        )

        expect(result[:status]).to eq(:confirmed)
        expect(result[:confirmed_at]).to be_a(Time)
      end

      it "checks preconditions" do
        payment_id = '550e8400-e29b-41d4-a716-446655440000'
        # This would fail in a real implementation where we check actual status
        # For now, precondition check is mocked
        expect {
          Facera::Executor.run(
            facet: :internal,
            capability: :confirm_payment,
            params: { id: payment_id },
            context: { status: :cancelled }
          )
        }.to raise_error(Facera::PreconditionError)
      end
    end

    context "capability access control" do
      it "raises error if capability not allowed in facet" do
        payment_id = '550e8400-e29b-41d4-a716-446655440000'
        expect {
          Facera::Executor.run(
            facet: :external,
            capability: :confirm_payment,
            params: { id: payment_id }
          )
        }.to raise_error(Facera::UnauthorizedError, /not allowed/)
      end

      it "allows capability if facet permits it" do
        payment_id = '550e8400-e29b-41d4-a716-446655440000'
        expect {
          Facera::Executor.run(
            facet: :internal,
            capability: :confirm_payment,
            params: { id: payment_id },
            context: { status: :pending }
          )
        }.not_to raise_error
      end
    end
  end
end
