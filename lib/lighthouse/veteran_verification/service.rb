# frozen_string_literal: true

require 'common/client/base'
require 'lighthouse/veteran_verification/configuration'
require 'lighthouse/service_exception'

module VeteranVerification
  class Service < Common::Client::Base
    configuration VeteranVerification::Configuration
    STATSD_KEY_PREFIX = 'api.veteran_verification'

    # @param [string] icn: the ICN of the target Veteran
    # @param [string] lighthouse_client_id: the lighthouse_client_id requested from Lighthouse
    # @param [string] lighthouse_rsa_key_path: path to the private RSA key used to create the lighthouse_client_id
    # @param [hash] options: options to override aud_claim_url, params, and auth_params
    # @option options [hash] :params body for the request
    # @option options [string] :aud_claim_url option to override the aud_claim_url for LH Veteran Verification APIs
    # @option options [hash] :auth_params a hash to send in auth params to create the access token
    # @option options [string] :host a base host for the Lighthouse API call
      def get_rated_disabilities(icn, lighthouse_client_id = nil, lighthouse_rsa_key_path = nil, options = {})
        process_request('disability_rating', icn, lighthouse_client_id, lighthouse_rsa_key_path, options)
      rescue => e
        handle_error(e, lighthouse_client_id, 'disability_rating')
      end

      def get_service_history(icn, lighthouse_client_id = nil, lighthouse_rsa_key_path = nil, options = {})
        process_request('service_history', icn, lighthouse_client_id, lighthouse_rsa_key_path, options)
      rescue => e
        handle_error(e, lighthouse_client_id, 'service_history')
      end

      private

      def process_request(endpoint, icn, lighthouse_client_id, lighthouse_rsa_key_path, options)
        config.get(endpoint + '/' + icn.to_s, lighthouse_client_id, lighthouse_rsa_key_path, options).body
      end

      def handle_error(error, lighthouse_client_id, endpoint)
        Lighthouse::ServiceException.send_error(
          error,
          self.class.to_s.underscore,
          lighthouse_client_id,
          "#{config.base_api_path}/#{endpoint}"
        )
      end
  end

