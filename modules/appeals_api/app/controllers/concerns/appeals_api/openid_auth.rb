# frozen_string_literal: true

require 'appeals_api/token_validation_client'

module AppealsApi
  module OpenidAuth
    extend ActiveSupport::Concern
    TOKEN_REGEX = /^Bearer (\S+)$/

    # These appeals_api-wide scopes should be allowed for any route using OAuth anywhere in the appeals APIs.
    DEFAULT_OAUTH_SCOPES = {
      GET: %w[appeals.read],
      PUT: %w[appeals.write],
      POST: %w[appeals.write]
    }.freeze

    # Controllers using this concern can override this constant to specify their own scopes.
    # Scopes defined this way will be allowed in addition to (not instead of) the default scopes above.
    OAUTH_SCOPES = {
      GET: %w[],
      PUT: %w[],
      POST: %w[]
    }.freeze

    included do
      prepend_before_action :validate_auth_token!
    end

    def audience_url
      "#{request.base_url == 'https://api.va.gov' ? 'https://api.va.gov' : 'https://sandbox-api.va.gov'}/services/appeals"
    end

    def find_auth_token!
      token_value = request.authorization.to_s[TOKEN_REGEX, 1]
      raise ::Common::Exceptions::Unauthorized if token_value.blank?

      token_value
    end

    def auth_token
      @auth_token ||= find_auth_token!
    end

    def token_validation_client
      @client ||= AppealsApi::TokenValidationClient.new(api_key: token_validation_api_key)
    end

    def validate_auth_token!
      token_validation_client.validate_token!(
        audience: audience_url,
        scopes: DEFAULT_OAUTH_SCOPES[request.method.to_sym].concat(self.class::OAUTH_SCOPES[request.method.to_sym]),
        token: auth_token
      )
    end

    private

    # Override this in individual controllers
    def token_validation_api_key
      raise 'Missing token validation API key'
    end
  end
end
