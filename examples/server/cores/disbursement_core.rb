# Disbursement Core
# Defines the semantic model for disbursement operations (ops-only)

Facera.define_core(:disbursement) do
  entity :disbursement do
    attribute :id, :uuid, immutable: true
    attribute :created_at, :timestamp, immutable: true

    attribute :amount, :money, required: true
    attribute :currency, :string, required: true
    attribute :recipient_id, :uuid, required: true
    attribute :merchant_id, :uuid, required: true

    attribute :reference, :string
    attribute :notes, :string

    attribute :status, :enum, values: [:scheduled, :processing, :completed, :failed]
    attribute :scheduled_at, :timestamp
    attribute :processed_at, :timestamp
    attribute :failed_at, :timestamp
    attribute :failure_reason, :string
  end

  invariant :positive_amount, description: "Disbursement amount must be positive" do
    amount.nil? || amount > 0
  end

  capability :create_disbursement, type: :create do
    entity :disbursement
    requires :amount, :currency, :recipient_id, :merchant_id
    optional :reference, :notes, :scheduled_at

    validates do
      amount > 0
    end
  end

  capability :get_disbursement, type: :get do
    entity :disbursement
    requires :id
  end

  capability :list_disbursements, type: :list do
    entity :disbursement
    optional :limit, :offset, :merchant_id, :recipient_id, :status
    filterable :merchant_id, :recipient_id, :status
  end

  capability :process_disbursement, type: :action do
    entity :disbursement
    requires :id

    precondition { status == :scheduled }
    transitions_to :processing
    sets processed_at: -> { Time.now }
  end

  capability :mark_failed, type: :action do
    entity :disbursement
    requires :id, :failure_reason

    precondition { status == :processing }
    transitions_to :failed
    sets failed_at: -> { Time.now }
  end
end
