require "rack"
require "rack/request"
require "rack/micro_service/signed_request/version"

require "micro_service/signed_request/utils"

module Rack
	module MicroService
		class SignedRequest
			def initialize(app, opts={}, &block)
				@app = app

				if block_given?
					if block.arity == 1
						block.call(self)
					else
						instance_eval(&block)
					end
				end
			end

			def call(env)
				request = Request.new(env)

				# Prefix to look for in Authorization header
				header_prefix = (!@prefix.nil?) ? @prefix.call() : "MicroService"

				# Only bother authenticating if the request is identifying itself as signed
				if env["HTTP_X_SHINDIG_AUTHTYPE"] === "signed" || env["HTTP_AUTHORIZATION"].to_s.match(/^#{header_prefix}/)
					auth_header_params = ::CGI.parse env["HTTP_AUTHORIZATION"].gsub(/^#{header_prefix}\s/,'')

					begin
						secret = @secret.call(auth_header_params)
						if ::MicroService::SignedRequest::Utils.validate(env["HTTP_AUTHORIZATION"], secret, header_prefix)
							env["micro_service.client_id"] = auth_header_params["client_id"].first
						else
							env["micro_service.errors.signed_request"] = "AUTHENTICATION_ERROR"
						end
					rescue ArgumentError => $e
						env["micro_service.errors.signed_request"] = $e.message
					end
				end

				@app.call(env)
			end

			def secret(&block)
				@secret = block
			end

			def prefix(&block)
				@prefix = block
			end
		end

		class Request < ::Rack::Request
		end
	end
end
