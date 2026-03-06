# Payment Core
# Defines the semantic model for payment operations

Facera.define_core(:payment) do
  # Payment entity with all attributes
  entity :payment do
    # Immutable identifiers
    attribute :id, :uuid, immutable: true
    attribute :created_at, :timestamp, immutable: true

    # Required payment information
    attribute :amount, :money, required: true
    attribute :currency, :string, required: true
    attribute :merchant_id, :uuid, required: true
    attribute :customer_id, :uuid, required: true

    # Optional information
    attribute :description, :string
    attribute :metadata, :hash

    # State tracking
    attribute :status, :enum, values: [:pending, :confirmed, :cancelled]
    attribute :confirmed_at, :timestamp
    attribute :cancelled_at, :timestamp
  end

  # Business invariants
  invariant :positive_amount, description: "Payment amount must be positive" do
    amount.nil? || amount > 0
  end

  invariant :valid_status_transitions, description: "Only valid state transitions allowed" do
    # This would check against actual previous state in a real implementation
    true
  end

  # Create a new payment
  capability :create_payment, type: :create do
    entity :payment
    requires :amount, :currency, :merchant_id, :customer_id
    optional :description, :metadata

    validates do
      amount > 0
    end
  end

  # Retrieve a specific payment
  capability :get_payment, type: :get do
    entity :payment
    requires :id
  end

  # List payments with optional filters
  capability :list_payments, type: :list do
    entity :payment
    optional :limit, :offset, :merchant_id, :customer_id, :status
    filterable :merchant_id, :customer_id, :status
  end

  # Confirm a pending payment
  capability :confirm_payment, type: :action do
    entity :payment
    requires :id
    optional :confirmation_code

    precondition { status == :pending }
    transitions_to :confirmed
    sets confirmed_at: -> { Time.now }
  end

  # Cancel a pending payment
  capability :cancel_payment, type: :action do
    entity :payment
    requires :id
    optional :reason

    precondition { status == :pending }
    transitions_to :cancelled
    sets cancelled_at: -> { Time.now }
  end
end
