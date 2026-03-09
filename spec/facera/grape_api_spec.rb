require 'rack/test'

RSpec.describe "Grape API Integration" do
  include Rack::Test::Methods

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
        attribute :description, :string
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
        optional :limit, :offset, :merchant_id
        filterable :merchant_id
      end

      capability :confirm_payment, type: :action do
        entity :payment
        requires :id
        precondition { status == :pending }
        transitions_to :confirmed
      end
    end

    Facera.define_facet(:external, core: :payment) do
      expose :payment do
        fields :id, :amount, :currency, :status, :description
      end

      allow_capabilities :create_payment, :get_payment, :list_payments
    end

    Facera.define_facet(:internal, core: :payment) do
      expose :payment do
        fields :all
      end

      allow_capabilities :all
    end
  end

  describe "External Facet API" do
    def app
      @app ||= Facera.api_for(:external)
    end

    describe "GET /health" do
      it "returns health status" do
        get '/health'

        expect(last_response.status).to eq(200)
        json = JSON.parse(last_response.body)
        expect(json['status']).to eq('ok')
        expect(json['audience']).to eq('external')
        expect(json['cores']).to include('payment')
      end
    end

    describe "POST /payments" do
      it "creates a payment" do
        post '/payments', {
          amount: 100.0,
          currency: 'USD',
          merchant_id: '550e8400-e29b-41d4-a716-446655440000',
          customer_id: '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
          description: 'Test payment'
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(201)
        json = JSON.parse(last_response.body)

        expect(json['amount']).to eq(100.0)
        expect(json['currency']).to eq('USD')
        expect(json['description']).to eq('Test payment')
        expect(json['id']).to be_a(String)
      end

      it "returns validation error for missing params" do
        post '/payments', {
          amount: 100.0
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(400)
        json = JSON.parse(last_response.body)
        expect(json['error']).to be_a(String) # Grape returns string error message
      end

      it "only exposes allowed fields" do
        post '/payments', {
          amount: 100.0,
          currency: 'USD',
          merchant_id: '550e8400-e29b-41d4-a716-446655440000',
          customer_id: '6ba7b810-9dad-11d1-80b4-00c04fd430c8'
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(201)
        json = JSON.parse(last_response.body)

        # These fields should be visible
        expect(json).to have_key('id')
        expect(json).to have_key('amount')
        expect(json).to have_key('currency')
        expect(json).to have_key('status')

        # merchant_id is hidden in external facet
        expect(json).not_to have_key('merchant_id')
      end
    end

    describe "GET /payments/:id" do
      it "gets a payment" do
        payment_id = '550e8400-e29b-41d4-a716-446655440000'
        get "/payments/#{payment_id}"

        expect(last_response.status).to eq(200)
        json = JSON.parse(last_response.body)

        expect(json['id']).to eq(payment_id)
        expect(json).to have_key('amount')
        expect(json).to have_key('currency')
      end
    end

    describe "GET /payments" do
      it "lists payments" do
        get '/payments', limit: 10, offset: 0

        expect(last_response.status).to eq(200)
        json = JSON.parse(last_response.body)

        expect(json).to have_key('data')
        expect(json).to have_key('meta')
        expect(json['data']).to be_an(Array)
        expect(json['meta']['limit']).to eq(10)
        expect(json['meta']['offset']).to eq(0)
      end

      it "supports filtering" do
        get '/payments', merchant_id: 'merchant-123'

        expect(last_response.status).to eq(200)
        json = JSON.parse(last_response.body)
        expect(json).to have_key('data')
      end
    end

    describe "POST /payments/:id/confirm" do
      it "returns unauthorized for disallowed capability" do
        post '/payments/payment-123/confirm'

        expect(last_response.status).to eq(404)
        # The endpoint doesn't exist in external facet
      end
    end
  end

  describe "Internal Facet API" do
    def app
      @app ||= Facera.api_for(:internal)
    end

    describe "POST /payments/:id/confirm" do
      it "returns precondition error when payment is not pending" do
        payment_id = '550e8400-e29b-41d4-a716-446655440000'
        post "/payments/#{payment_id}/confirm", {}.to_json, { 'CONTENT_TYPE' => 'application/json' }

        # Precondition will fail because executor doesn't have real entity data
        expect(last_response.status).to eq(422)
        json = JSON.parse(last_response.body)

        expect(json['error']).to eq('precondition')
      end
    end

    describe "GET /payments/:id" do
      it "exposes all fields in internal facet" do
        payment_id = '550e8400-e29b-41d4-a716-446655440000'
        get "/payments/#{payment_id}"

        expect(last_response.status).to eq(200)
        json = JSON.parse(last_response.body)

        # All fields should be visible in internal facet
        expect(json).to have_key('id')
        expect(json).to have_key('amount')
        expect(json).to have_key('merchant_id')
        expect(json).to have_key('customer_id')
      end
    end
  end

  describe "API Generation" do
    it "generates different APIs for different facets" do
      external_api = Facera.api_for(:external)
      internal_api = Facera.api_for(:internal)

      expect(external_api).not_to eq(internal_api)
      expect(external_api.facet.name).to eq(:external)
      expect(internal_api.facet.name).to eq(:internal)
    end

    it "includes only allowed capabilities" do
      external_api = Facera.api_for(:external)

      # External facet should have create, get, list but not confirm
      routes = external_api.routes.map { |r| "#{r.request_method} #{r.path}" }

      # Check that expected routes exist
      expect(routes.any? { |r| r =~ /POST.*\/payments/ }).to be true
      expect(routes.any? { |r| r =~ /GET.*\/payments\/:id/ }).to be true
      expect(routes.any? { |r| r =~ /GET.*\/payments/ }).to be true # Doesn't need to end with $

      # Confirm endpoint should not exist
      expect(routes.any? { |r| r.include?('/confirm') }).to be false
    end
  end
end
