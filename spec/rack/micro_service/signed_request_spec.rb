require 'spec_helper'

describe Rack::MicroService::SignedRequest do
	CLIENT_ID = "682a638ba74a4ff5fa6afa344b163e03.i"
	ALGORITHM = "sha256";
	URL = "https://server.local"
	SECRET = "8bd2952b851747e8f2c937b340fed6e1.s";
	PREFIX = "MicroService"

	let(:app) { proc { |env|
		[200, env, ['succes']] }
	}

	let(:middleware) {
		Rack::MicroService::SignedRequest.new(app, {}) do
			secret do |auth_header_params|
				SECRET
			end
		end
	}

	def env_for url, opts={}
		Rack::MockRequest.env_for(url, opts)
	end

	describe 'when signed request header is valid' do
		it 'should not process requests that dont identify themselves as signed requests' do
			timestamp = (Time.now.to_i)*1000
			str = "algorithm=HmacSHA256&client_id=#{CLIENT_ID}&service_url=#{CGI.escape(URL)}&timestamp=#{timestamp}";
			signature = ::MicroService::SignedRequest::Utils.sign(str, SECRET, ALGORITHM)
			authorization_header = "#{str}&signature=#{CGI::escape(signature)}";

			code, env, body = middleware.call env_for('/', {
				:method => "POST",
				"HTTP_AUTHORIZATION" => authorization_header,
			})

			expect(env["micro_service.errors.signed_request"]).to eq(nil)
		end

		it 'should populate the env with jive variables', :focus => true do
			timestamp = (Time.now.to_i)*1000
			str = "algorithm=HmacSHA256&client_id=#{CLIENT_ID}&service_url=#{CGI.escape(URL)}&timestamp=#{timestamp}";
			signature = ::MicroService::SignedRequest::Utils.sign(str, SECRET, ALGORITHM)
			authorization_header = "MicroService #{str}&signature=#{CGI::escape(signature)}";

			code, env, body = middleware.call env_for('/', {
				:method => "POST",
				"HTTP_AUTHORIZATION" => authorization_header,
			})

			expect(env["micro_service.errors.signed_request"]).to eq(nil)
			expect(env["micro_service.client_id"]).to eq(CLIENT_ID)
		end
	end

	describe 'when signed request header is invalid' do
		it 'rejects the request when expired' do
			# First build a valid signature
			timestamp = (Time.now.to_i-(6*60))*1000
			str = "algorithm=HmacSHA256&client_id=#{CLIENT_ID}&service_url=#{CGI.escape(URL)}&timestamp=#{timestamp}";
			signature = ::MicroService::SignedRequest::Utils.sign(str, SECRET, ALGORITHM)
			authorization_header = "MicroService #{str}&signature=#{CGI::escape(signature)}";

			code, env, body = middleware.call env_for('/', {
				:method => "POST",
				"HTTP_X_SHINDIG_AUTHTYPE" => "signed",
				"HTTP_AUTHORIZATION" => authorization_header,
			})

			expect(env["micro_service.errors.signed_request"]).to_not eq(nil)
			expect(env["micro_service.client_id"]).to eq(nil)
		end

		it 'rejects the request when malformed' do
			# First build a valid signature
			timestamp = (Time.now.to_i-(3*60))*1000
			str = "algorithm=HmacSHA256&client_id=#{CLIENT_ID}-err&service_url=#{CGI.escape(URL)}&timestamp=#{timestamp}";
			signature = ::MicroService::SignedRequest::Utils.sign(str, SECRET, ALGORITHM)
			authorization_header = "MicroService #{str}&signature=#{CGI::escape(signature)}-malform";

			code, env, body = middleware.call env_for('/', {
				:method => "POST",
				"HTTP_X_SHINDIG_AUTHTYPE" => "signed",
				"HTTP_AUTHORIZATION" => authorization_header,
			})

			expect(env["micro_service.errors.signed_request"]).to_not eq(nil)
			expect(env["micro_service.client_id"]).to eq(nil)
		end
	end
end
