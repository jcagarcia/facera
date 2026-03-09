# Disbursement Adapter
# Implements business logic for disbursement core capabilities

class DisbursementAdapter
  include Facera::Adapter

  @@disbursements = {}

  def create_disbursement(params)
    disbursement = {
      id: SecureRandom.uuid,
      amount: params[:amount],
      currency: params[:currency],
      recipient_id: params[:recipient_id],
      merchant_id: params[:merchant_id],
      reference: params[:reference],
      notes: params[:notes],
      status: :scheduled,
      scheduled_at: params[:scheduled_at] || Time.now,
      created_at: Time.now
    }

    @@disbursements[disbursement[:id]] = disbursement

    disbursement
  end

  def get_disbursement(params)
    disbursement = @@disbursements[params[:id]]
    raise Facera::NotFoundError, "Disbursement not found" unless disbursement
    disbursement
  end

  def list_disbursements(params)
    disbursements = @@disbursements.values

    disbursements = disbursements.select { |d| d[:merchant_id] == params[:merchant_id] } if params[:merchant_id]
    disbursements = disbursements.select { |d| d[:recipient_id] == params[:recipient_id] } if params[:recipient_id]
    disbursements = disbursements.select { |d| d[:status].to_s == params[:status].to_s } if params[:status]

    limit  = (params[:limit]  || 20).to_i
    offset = (params[:offset] ||  0).to_i

    {
      data: disbursements[offset, limit] || [],
      meta: { total: disbursements.count, limit: limit, offset: offset }
    }
  end

  def process_disbursement(params)
    disbursement = get_disbursement(params)

    unless disbursement[:status] == :scheduled
      raise Facera::PreconditionError, "Disbursement must be scheduled to process"
    end

    disbursement[:status] = :processing
    disbursement[:processed_at] = Time.now

    disbursement
  end

  def mark_failed(params)
    disbursement = get_disbursement(params)

    unless disbursement[:status] == :processing
      raise Facera::PreconditionError, "Disbursement must be processing to mark as failed"
    end

    disbursement[:status] = :failed
    disbursement[:failed_at] = Time.now
    disbursement[:failure_reason] = params[:failure_reason]

    disbursement
  end
end
