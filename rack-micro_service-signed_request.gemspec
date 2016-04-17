# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/micro_service/signed_request/version'

Gem::Specification.new do |spec|
	spec.name          = "rack-micro_service-signed_request"
	spec.version       = Rack::MicroService::SignedRequest::VERSION
	spec.authors       = ["Butch Marshall"]
	spec.email         = ["butch.a.marshall@gmail.com"]
	
	spec.summary       = %q{Rack middleware for MicroService signed requests.}
	spec.description   = %q{Authenticates signed server requests from a MicroService and resolves the MicroService.}
	spec.homepage      = "https://github.com/butchmarshall/rack-micro_service-signed_request"
	spec.license       = "MIT"

	spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
	spec.bindir        = "exe"
	spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
	spec.require_paths = ["lib"]

	spec.add_dependency "micro_service-signed_request-utils"

	spec.add_development_dependency "bundler", "~> 1.10"
	spec.add_development_dependency "rake", "~> 10.0"
	spec.add_development_dependency "rspec"

	spec.add_runtime_dependency "rack", ">= 1.1"
end
