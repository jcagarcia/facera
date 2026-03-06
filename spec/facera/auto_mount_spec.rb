RSpec.describe Facera::AutoMount do
  before do
    Facera::Registry.reset!
    Facera.reset_configuration!
  end

  describe "configuration" do
    it "allows configuration via block" do
      Facera.configure do |config|
        config.base_path = '/api'
        config.version = 'v2'
        config.dashboard = false
      end

      config = Facera.configuration
      expect(config.base_path).to eq('/api')
      expect(config.version).to eq('v2')
      expect(config.dashboard).to be false
    end

    it "supports custom facet paths" do
      Facera.configure do |config|
        config.facet_path :external, '/public/v1'
        config.facet_path :internal, '/services/v1'
      end

      config = Facera.configuration
      expect(config.path_for_facet(:external)).to eq('/public/v1')
      expect(config.path_for_facet(:internal)).to eq('/services/v1')
    end

    it "supports disabling facets" do
      Facera.configure do |config|
        config.disable_facet :agent
        config.disable_facet :operator
      end

      config = Facera.configuration
      expect(config.facet_enabled?(:external)).to be true
      expect(config.facet_enabled?(:agent)).to be false
      expect(config.facet_enabled?(:operator)).to be false
    end

    it "provides default paths for common facets" do
      config = Facera.configuration

      expect(config.path_for_facet(:external)).to eq('/v1')
      expect(config.path_for_facet(:internal)).to eq('/internal/v1')
      expect(config.path_for_facet(:operator)).to eq('/operator/v1')
      expect(config.path_for_facet(:agent)).to eq('/agent/v1')
    end

    it "supports authentication handlers" do
      handler = proc { |request| "user" }

      Facera.configure do |config|
        config.authenticate :external, &handler
      end

      config = Facera.configuration
      expect(config.authentication_handler_for(:external)).to eq(handler)
    end

    it "requires block for authentication" do
      expect {
        Facera.configure do |config|
          config.authenticate :external
        end
      }.to raise_error(Facera::Error, /Authentication block required/)
    end
  end

  describe "path generation" do
    it "generates full paths with base_path" do
      Facera.configure do |config|
        config.base_path = '/api'
        config.version = 'v1'
      end

      config = Facera.configuration
      expect("#{config.base_path}#{config.path_for_facet(:external)}").to eq('/api/v1')
      expect("#{config.base_path}#{config.path_for_facet(:internal)}").to eq('/api/internal/v1')
    end

    it "uses custom paths when provided" do
      Facera.configure do |config|
        config.base_path = '/api'
        config.facet_path :external, '/public'
      end

      config = Facera.configuration
      expect("#{config.base_path}#{config.path_for_facet(:external)}").to eq('/api/public')
    end
  end

  describe "reset" do
    it "resets configuration to defaults" do
      Facera.configure do |config|
        config.base_path = '/custom'
        config.version = 'v2'
      end

      Facera.reset_configuration!

      config = Facera.configuration
      expect(config.base_path).to eq('/api')
      expect(config.version).to eq('v1')
    end
  end
end
