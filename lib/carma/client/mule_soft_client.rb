# frozen_string_literal: true

require 'carma/client/mule_soft_configuration'

module CARMA
  module Client
    class MuleSoftClient < Common::Client::Base
      include Common::Client::Concerns::Monitoring

      configuration MuleSoftConfiguration

      STATSD_KEY_PREFIX = 'api.carma.mulesoft'

      class RecordParseError < StandardError; end

      def create_submission_v2(payload)
        with_monitoring do
          res = if Flipper.enabled?(:cg_OAuth_2_enabled)
                  perform_post('v2/application/1010CG/submit', payload)
                else
                  do_post('v2/application/1010CG/submit', payload, config.settings.async_timeout)
                end

          raise RecordParseError if res.dig('record', 'hasErrors')

          res
        end
      end

      private

      # @param resource [String] REST-ful path component
      # @param payload [String] JSON payload to submit
      # @return [Hash]
      def do_post(resource, payload, timeout = config.timeout)
        with_monitoring do
          Rails.logger.info "[Form 10-10CG] Submitting to '#{resource}'"
          args = post_args(resource, payload, timeout)
          response = perform(*args)

          handle_response(resource, response)
        end
      end

      # @return [Array]
      def post_args(resource, payload, timeout)
        headers = config.base_request_headers
        opts = { timeout: }
        [:post, resource, get_body(payload), headers, opts]
      end

      def get_body(payload)
        payload.is_a?(String) ? payload : payload.to_json
      end

      def handle_response(resource, response)
        Sentry.set_extras(response_body: response.body)
        raise_error_unless_success(resource, response.status)
        JSON.parse(response.body)
      end

      def raise_error_unless_success(resource, status)
        Rails.logger.info "[Form 10-10CG] Submission to '#{resource}' resource resulted in response code #{status}"
        return if [200, 201, 202].include? status

        raise Common::Exceptions::SchemaValidationErrors, ["Expecting 200 status but received #{status}"]
      end

      # New Authentication strategy

      # Call Mulesoft with bearer token
      def perform_post(resource, payload)
        Rails.logger.info "[Form 10-10CG] Submitting to '#{resource}' using bearer token"

        response = perform(:post, resource, get_body(payload), { Authorization: "Bearer #{bearer_token}" })

        handle_response(resource, response)
      end

      # get token
      def bearer_token
        @bearer_token ||= get_new_bearer_token
      end

      def get_new_bearer_token
        encoded_params = URI.encode_www_form({
                                               grant_type: 'client_credentials',
                                               scope: 'read' # TODO: this is probably a write?
                                             })

        basic_auth =  Base64.urlsafe_encode64("#{config.settings.v2.client_id}:#{config.settings.v2.client_secret}")

        token_headers = {
          'Authorization' => "Basic #{basic_auth}",
          'Content-Type' => 'application/x-www-form-urlencoded'
        }

        response = perform(:post,
                           config.settings.v2.token_url,
                           encoded_params,
                           token_headers)
        response.body[:access_token]
      end
    end
  end
end
