require_relative 'lib/facera/version'

Gem::Specification.new do |spec|
  spec.name          = "facera"
  spec.version       = Facera::VERSION
  spec.authors       = ["Juan Carlos Garcia"]
  spec.email         = ["jugade92@gmail.com"]

  spec.summary       = "A Ruby framework for building multi-facet APIs from a single semantic core"
  spec.description   = "Facera allows you to define your system once as a semantic core and expose it through multiple facets, each tailored to different consumers while remaining logically consistent."
  spec.homepage      = "https://github.com/jcagarcia/facera"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "grape", "~> 2.0"
  spec.add_dependency "grape-entity", "~> 1.0"
end
