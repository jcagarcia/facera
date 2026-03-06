require_relative '../lib/facera'

# Define a payment core with entities, capabilities, and invariants
payment_core = Facera.define_core(:payment) do
  # Define the payment entity
  entity :payment do
    attribute :id, :uuid, immutable: true
    attribute :amount, :money, required: true
    attribute :currency, :string, required: true
    attribute :status, :enum, values: [:pending, :confirmed, :cancelled, :refunded]
    attribute :merchant_id, :uuid, required: true
    attribute :customer_id, :uuid, required: true
    attribute :description, :string
    attribute :metadata, :hash
    attribute :created_at, :timestamp, immutable: true
    attribute :updated_at, :timestamp
    attribute :confirmed_at, :timestamp
    attribute :cancelled_at, :timestamp
  end

  # Define business invariants
  invariant :positive_amount, description: "Amount must be positive" do
    amount > 0
  end

  invariant :valid_status_transitions, description: "Only valid state transitions allowed" do
    case status
    when :pending then [:confirmed, :cancelled]
    when :confirmed then [:refunded]
    when :cancelled then []
    when :refunded then []
    else []
    end
  end

  invariant :timestamps_coherent, description: "Confirmed timestamp must be after creation" do
    confirmed_at.nil? || confirmed_at >= created_at
  end

  # Define capabilities
  capability :create_payment, type: :create do
    entity :payment
    requires :amount, :currency, :merchant_id, :customer_id
    optional :description, :metadata

    validates do
      amount > 0
    end
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

  capability :confirm_payment, type: :action do
    entity :payment
    requires :id
    optional :confirmation_code

    precondition { status == :pending }
    transitions_to :confirmed
    sets confirmed_at: -> { Time.now }
  end

  capability :cancel_payment, type: :action do
    entity :payment
    requires :id
    optional :reason

    precondition { status == :pending }
    transitions_to :cancelled
    sets cancelled_at: -> { Time.now }
  end

  capability :refund_payment, type: :action do
    entity :payment
    requires :id
    optional :amount, :reason

    precondition { status == :confirmed }
    transitions_to :refunded

    validates do
      amount.nil? || amount <= payment.amount
    end
  end
end

# Display the core structure
puts "=" * 60
puts "Payment Core Definition"
puts "=" * 60
puts

puts "Entities (#{payment_core.entities.count}):"
payment_core.entities.each do |name, entity|
  puts "  #{name}"
  puts "    Attributes: #{entity.attributes.keys.join(', ')}"
  puts "    Required: #{entity.required_attributes.map(&:name).join(', ')}"
  puts "    Immutable: #{entity.immutable_attributes.map(&:name).join(', ')}"
end
puts

puts "Invariants (#{payment_core.invariants.count}):"
payment_core.invariants.each do |name, invariant|
  puts "  #{name}: #{invariant.description}"
end
puts

puts "Capabilities (#{payment_core.capabilities.count}):"
payment_core.capabilities.each do |name, capability|
  puts "  #{name} (#{capability.type})"
  puts "    Required params: #{capability.required_params.join(', ')}" if capability.required_params.any?
  puts "    Optional params: #{capability.optional_params.join(', ')}" if capability.optional_params.any?
  puts "    Preconditions: #{capability.preconditions.count}" if capability.preconditions.any?
  puts "    Validations: #{capability.validations.count}" if capability.validations.any?
  puts "    Transitions to: #{capability.transitions.join(', ')}" if capability.transitions.any?
end
puts

puts "=" * 60
puts "Core successfully defined and registered!"
puts "=" * 60
