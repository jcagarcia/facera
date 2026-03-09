# Refund Core
# Defines the semantic model for refund operations

Facera.define_core(:refund) do
  # Refund entity with all attributes
  entity :refund do
    # Immutable identifiers
    attribute :id, :uuid, immutable: true
    attribute :created_at, :timestamp, immutable: true

    # Required refund information
    attribute :payment_id, :uuid, required: true
    attribute :amount, :money, required: true
    attribute :currency, :string, required: true
    attribute :customer_id, :uuid, required: true

    # Optional information
    attribute :reason, :string
    attribute :notes, :string

    # State tracking
    attribute :status, :enum, values: [:pending, :approved, :rejected, :processed]
    attribute :approved_at, :timestamp
    attribute :rejected_at, :timestamp
    attribute :processed_at, :timestamp
    attribute :rejection_reason, :string
  end

  # Business invariants
  invariant :positive_refund_amount, description: "Refund amount must be positive" do
    amount.nil? || amount > 0
  end

  invariant :valid_refund_transitions, description: "Only valid state transitions allowed" do
    true
  end

  # Request a new refund
  capability :create_refund, type: :create do
    entity :refund
    requires :payment_id, :amount, :currency, :customer_id
    optional :reason, :notes

    validates do
      amount > 0
    end
  end

  # Retrieve a specific refund
  capability :get_refund, type: :get do
    entity :refund
    requires :id
  end

  # List refunds with optional filters
  capability :list_refunds, type: :list do
    entity :refund
    optional :limit, :offset, :payment_id, :customer_id, :status
    filterable :payment_id, :customer_id, :status
  end

  # Approve a pending refund
  capability :approve_refund, type: :action do
    entity :refund
    requires :id
    optional :notes

    precondition { status == :pending }
    transitions_to :approved
    sets approved_at: -> { Time.now }
  end

  # Reject a pending refund
  capability :reject_refund, type: :action do
    entity :refund
    requires :id, :rejection_reason

    precondition { status == :pending }
    transitions_to :rejected
    sets rejected_at: -> { Time.now }
  end

  # Process an approved refund (mark as paid out)
  capability :process_refund, type: :action do
    entity :refund
    requires :id

    precondition { status == :approved }
    transitions_to :processed
    sets processed_at: -> { Time.now }
  end
end
