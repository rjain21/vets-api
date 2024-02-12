# frozen_string_literal: true

require 'dgi/configuration'
require 'faraday/multipart'

module MebApi
  module DGI
    module Letters
      class Configuration < Common::Client::Configuration::REST
        def base_path
          Settings.dgi.vets.url.to_s
        end

        def connection
          @conn ||= Faraday.new(base_path, headers: base_request_headers, request: request_options) do |faraday|
            faraday.use :breakers
            faraday.use Faraday::Response::RaiseError

            faraday.request :multipart
            faraday.response :betamocks if mock_enabled?
            faraday.adapter Faraday.default_adapter
          end
        end

        def mock_enabled?
          Settings.dgi.vets.mock || false
        end
      end
    end
  end
end
