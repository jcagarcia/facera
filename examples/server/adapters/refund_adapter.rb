# Refund Adapter
# Implements business logic for refund core capabilities
#
# This adapter uses in-memory storage for demo purposes.
# In production, you would use ActiveRecord, Sequel, or your preferred ORM.

class RefundAdapter
  include Facera::Adapter

  # In-memory storage (for demo purposes)
  @@refunds = {}

  def create_refund(params)
    refund = {
      id: SecureRandom.uuid,
      payment_id: params[:payment_id],
      amount: params[:amount],
      currency: params[:currency],
      customer_id: params[:customer_id],
      reason: params[:reason],
      notes: params[:notes],
      status: :pending,
      created_at: Time.now
    }

    @@refunds[refund[:id]] = refund

    # In production, you might:
    # - Save to database: Refund.create!(params)
    # - Notify the payment service
    # - Trigger review workflow
    # - Send acknowledgement email to customer

    refund
  end

  def get_refund(params)
    refund = @@refunds[params[:id]]
    raise Facera::NotFoundError, "Refund not found" unless refund
    refund
  end

  def list_refunds(params)
    refunds = @@refunds.values

    if params[:payment_id]
      refunds = refunds.select { |r| r[:payment_id] == params[:payment_id] }
    end

    if params[:customer_id]
      refunds = refunds.select { |r| r[:customer_id] == params[:customer_id] }
    end

    if params[:status]
      refunds = refunds.select { |r| r[:status].to_s == params[:status].to_s }
    end

    limit  = (params[:limit]  || 20).to_i
    offset = (params[:offset] || 0).to_i

    {
      data: refunds[offset, limit] || [],
      meta: {
        total: refunds.count,
        limit: limit,
        offset: offset
      }
    }
  end

  def approve_refund(params)
    refund = get_refund(params)

    if refund[:status] != :pending
      raise Facera::PreconditionError, "Refund must be pending to approve"
    end

    refund[:status]      = :approved
    refund[:approved_at] = Time.now
    refund[:notes]       = params[:notes] if params[:notes]

    # In production, you might:
    # - Notify customer of approval
    # - Trigger payment gateway refund
    # - Update accounting records

    refund
  end

  def reject_refund(params)
    refund = get_refund(params)

    if refund[:status] != :pending
      raise Facera::PreconditionError, "Refund must be pending to reject"
    end

    refund[:status]           = :rejected
    refund[:rejected_at]      = Time.now
    refund[:rejection_reason] = params[:rejection_reason]

    # In production, you might:
    # - Notify customer of rejection with reason
    # - Log rejection for compliance

    refund
  end

  def process_refund(params)
    refund = get_refund(params)

    if refund[:status] != :approved
      raise Facera::PreconditionError, "Refund must be approved before processing"
    end

    refund[:status]       = :processed
    refund[:processed_at] = Time.now

    # In production, you might:
    # - Execute the actual bank transfer or card reversal
    # - Send confirmation email to customer
    # - Publish event: RefundEvents.publish(:refund_processed, refund)
    # - Update merchant settlement report

    refund
  end
end
