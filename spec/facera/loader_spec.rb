RSpec.describe Facera::Loader do
  before do
    Facera::Registry.reset!
  end

  describe "#initialize" do
    it "creates a loader with default load paths" do
      loader = Facera::Loader.new
      expect(loader.load_paths).to be_an(Array)
    end

    it "accepts custom load paths" do
      loader = Facera::Loader.new(load_paths: ['/custom/path'])
      expect(loader.load_paths).to eq(['/custom/path'])
    end
  end

  describe "auto-discovery" do
    it "discovers cores from conventional directories" do
      # This test verifies the discovery mechanism works
      # Actual file loading is tested in integration tests
      loader = Facera::Loader.new(load_paths: [Dir.pwd])
      files = loader.send(:discover_files, 'cores')

      expect(files).to be_an(Array)
    end

    it "discovers facets from conventional directories" do
      loader = Facera::Loader.new(load_paths: [Dir.pwd])
      files = loader.send(:discover_files, 'facets')

      expect(files).to be_an(Array)
    end

    it "returns files in sorted order" do
      loader = Facera::Loader.new(load_paths: [Dir.pwd])
      files = loader.send(:discover_files, 'facets')

      # Files should be sorted
      expect(files).to eq(files.sort)
    end
  end

  describe "load patterns" do
    it "checks app/cores/ directory" do
      loader = Facera::Loader.new(load_paths: ['/base'])
      expect(Dir).to receive(:glob).with('/base/app/cores/**/*.rb').and_return([])
      expect(Dir).to receive(:glob).with('/base/cores/**/*.rb').and_return([])
      expect(Dir).to receive(:glob).with('/base/lib/cores/**/*.rb').and_return([])

      loader.send(:discover_files, 'cores')
    end

    it "checks cores/ directory" do
      loader = Facera::Loader.new(load_paths: ['/base'])
      expect(Dir).to receive(:glob).with('/base/app/cores/**/*.rb').and_return([])
      expect(Dir).to receive(:glob).with('/base/cores/**/*.rb').and_return([])
      expect(Dir).to receive(:glob).with('/base/lib/cores/**/*.rb').and_return([])

      loader.send(:discover_files, 'cores')
    end

    it "checks lib/cores/ directory" do
      loader = Facera::Loader.new(load_paths: ['/base'])
      expect(Dir).to receive(:glob).with('/base/app/cores/**/*.rb').and_return([])
      expect(Dir).to receive(:glob).with('/base/cores/**/*.rb').and_return([])
      expect(Dir).to receive(:glob).with('/base/lib/cores/**/*.rb').and_return([])

      loader.send(:discover_files, 'cores')
    end
  end

  describe ".load_all!" do
    it "provides a class method for loading" do
      expect(Facera).to respond_to(:load_all!)
    end
  end

  describe ".load_cores!" do
    it "provides a class method for loading cores" do
      expect(Facera).to respond_to(:load_cores!)
    end
  end

  describe ".load_facets!" do
    it "provides a class method for loading facets" do
      expect(Facera).to respond_to(:load_facets!)
    end
  end
end
