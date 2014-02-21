# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bosh/manifests/version'

Gem::Specification.new do |spec|
  spec.name          = "bosh-manifests"
  spec.version       = Bosh::Manifests::VERSION
  spec.authors       = ["Ruben Koster"]
  spec.email         = ["rkoster@starkandwayne.com"]
  spec.description   = %q{Create & manage bosh manifests}
  spec.summary       = %q{Create & manage spiff based bosh manifests}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "bosh_cli", "~> 1.1782.0"
  spec.add_runtime_dependency "git", "~> 1.2.6"
  spec.add_runtime_dependency "psych", "~> 2.0.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rspec", "~> 2.13.0"
  spec.add_development_dependency "rspec-fire"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "archive-zip", "~> 0.6.0"
end
