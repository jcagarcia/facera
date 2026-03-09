# Payment Adapter
# Implements business logic for payment core capabilities
#
# This adapter uses in-memory storage for demo purposes.
# In production, you would use ActiveRecord, Sequel, or your preferred ORM.

class PaymentAdapter
  include Facera::Adapter

  # In-memory storage (for demo purposes)
  @@payments = {}

  def create_payment(params)
    payment = {
      id: SecureRandom.uuid,
      amount: params[:amount],
      currency: params[:currency],
      merchant_id: params[:merchant_id],
      customer_id: params[:customer_id],
      status: :pending,
      created_at: Time.now
    }

    @@payments[payment[:id]] = payment

    # In production, you might:
    # - Save to database: Payment.create!(params)
    # - Validate with external service
    # - Send notification
    # - Log audit trail

    payment
  end

  def get_payment(params)
    payment = @@payments[params[:id]]

    raise Facera::NotFoundError, "Payment not found" unless payment

    payment
  end

  def list_payments(params)
    payments = @@payments.values

    # Apply filters
    if params[:merchant_id]
      payments = payments.select { |p| p[:merchant_id] == params[:merchant_id] }
    end

    if params[:customer_id]
      payments = payments.select { |p| p[:customer_id] == params[:customer_id] }
    end

    if params[:status]
      payments = payments.select { |p| p[:status].to_s == params[:status].to_s }
    end

    # Apply pagination
    limit = (params[:limit] || 20).to_i
    offset = (params[:offset] || 0).to_i

    {
      data: payments[offset, limit] || [],
      meta: {
        total: payments.count,
        limit: limit,
        offset: offset
      }
    }
  end

  def confirm_payment(params)
    payment = get_payment(params)

    # Validate precondition (already done by framework, but good practice)
    if payment[:status] != :pending
      raise Facera::PreconditionError, "Payment must be pending to confirm"
    end

    # Update payment
    payment[:status] = :confirmed
    payment[:confirmed_at] = Time.now

    # In production, you might:
    # - Call payment gateway API
    # - Send confirmation email: PaymentMailer.confirmation(payment).deliver_later
    # - Publish event: PaymentEvents.publish(:payment_confirmed, payment)
    # - Update accounting system
    # - Trigger fulfillment workflow

    payment
  end

  def cancel_payment(params)
    payment = get_payment(params)

    if payment[:status] != :pending
      raise Facera::PreconditionError, "Payment must be pending to cancel"
    end

    payment[:status] = :cancelled
    payment[:cancelled_at] = Time.now

    # In production:
    # - Refund if already charged
    # - Send cancellation email
    # - Log cancellation reason
    # - Update metrics

    payment
  end

  def refund_payment(params)
    payment = get_payment(params)

    if payment[:status] != :confirmed
      raise Facera::PreconditionError, "Payment must be confirmed to refund"
    end

    refund_amount = params[:refund_amount] || payment[:amount]

    if refund_amount > payment[:amount]
      raise Facera::ValidationError, "Refund amount cannot exceed payment amount"
    end

    payment[:status] = :refunded
    payment[:refunded_at] = Time.now
    payment[:refund_amount] = refund_amount

    # In production:
    # - Process refund with payment gateway
    # - Send refund confirmation
    # - Update accounting
    # - Notify merchant

    payment
  end
end
