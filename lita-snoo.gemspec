Gem::Specification.new do |spec|
  spec.name          = "lita-snoo"
  spec.version       = "0.1.1"
  spec.authors       = ["Tristan Chong"]
  spec.email         = ["ong@tristaneuan.ch"]
  spec.description   = "A Lita handler for reddit that can detect imgur (or custom) URLs and find their original posts"
  spec.summary       = "A Lita handler for reddit that can detect imgur (or custom) URLs and find their original posts"
  spec.homepage      = "https://github.com/tristaneuan/lita-snoo"
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.3"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
end
