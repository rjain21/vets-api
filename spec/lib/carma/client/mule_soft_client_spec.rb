# frozen_string_literal: true

require 'rails_helper'
require 'carma/client/mule_soft_client'

class MockFaradayResponse
  attr_reader :body, :status

  def initialize(body, status = 200)
    @body = body
    @status = status
  end
end

describe CARMA::Client::MuleSoftClient do
  let(:client) { described_class.new }

  describe '#raise_error_unless_success' do
    context 'with a 202 status code' do
      it 'returns nil' do
        expect(
          client.send(:raise_error_unless_success, '', 202)
        ).to eq(nil)
      end
    end
  end

  describe 'submitting 10-10CG' do
    let(:config) { double('config') }
    let(:exp_headers) { { client_id: '1234', client_secret: 'abcd' } }
    let(:timeout) { 60 }

    before do
      allow(Rails.logger).to receive(:info)
      allow(client).to receive(:config).and_return(config)
      allow(config).to receive_messages(base_request_headers: exp_headers, timeout: 10,
                                        settings: OpenStruct.new(
                                          async_timeout: timeout,
                                          client_id: 'id',
                                          client_secret: 'secret'
                                        ))
    end

    describe '#create_submission_v2' do
      subject { client.create_submission_v2(payload) }

      let(:token_params) do
        URI.encode_www_form({
                              grant_type: 'client_credentials',
                              scope: 'read'
                            })
      end

      let(:token_headers) do
        {
          'Authorization' => "Basic #{basic_auth}",
          'Content-Type' => 'application/x-www-form-urlencoded'
        }
      end
      let(:basic_auth) do
        Base64.urlsafe_encode64("#{config.settings.client_id}:#{config.settings.client_secret}")
      end

      let(:token) { 'my-token' }

      let(:resource) { 'v2/application/1010CG/submit' }
      let(:has_errors) { false }
      let(:response_body) do
        {
          data: {
            carmacase: {
              createdAt: '2022-08-04 16:44:37',
              id: 'aB93S0000000FTqSAM'
            }
          },
          record: {
            hasErrors: has_errors
          }
        }.to_json
      end
      let(:mock_success_response) { MockFaradayResponse.new(response_body, 201) }
      let(:mock_token_response) { MockFaradayResponse.new({ access_token: token }, 201) }
      let(:payload) { {} }

      context 'OAuth 2.0 flipper enabled' do
        before do
          allow(client).to receive(:perform)
            .with(:post, 'dtc-va.okta-gov.com/oauth2/default/v1', token_params, token_headers)
            .and_return(mock_token_response)
          Flipper.enable(:cg_OAuth_2_enabled)
        end

        after do
          Flipper.disable(:cg_OAuth_2_enabled)
        end

        it 'calls perform with expected params' do
          expect(client).to receive(:perform)
            .with(:post, resource, payload.to_json, { Authorization: "Bearer #{token}" })
            .and_return(mock_success_response)

          expect(Rails.logger).to receive(:info).with("[Form 10-10CG] Submitting to '#{resource}' using bearer token")
          expect(Rails.logger).to receive(:info)
            .with("[Form 10-10CG] Submission to '#{resource}' resource resulted in response code 201")
          expect(Sentry).to receive(:set_extras).with(response_body: mock_success_response.body)

          subject
        end

        context 'with errors' do
          let(:has_errors) { true }
          let(:mock_error_response) { MockFaradayResponse.new(response_body, 500) }

          it 'raises SchemaValidationError' do
            expect(client).to receive(:perform)
              .with(:post, resource, payload.to_json, { Authorization: "Bearer #{token}" })
              .and_return(mock_error_response)

            expect(Rails.logger).to receive(:info).with("[Form 10-10CG] Submitting to '#{resource}' using bearer token")
            expect(Rails.logger).to receive(:info)
              .with("[Form 10-10CG] Submission to '#{resource}' resource resulted in response code 500")
            expect(Sentry).to receive(:set_extras).with(response_body: mock_success_response.body)

            expect { subject }.to raise_error(Common::Exceptions::SchemaValidationErrors)
          end
        end
      end

      context 'OAuth 2.0 flipper disabled' do
        let(:response_body) do
          {
            data: {
              carmacase: {
                createdAt: '2022-08-04 16:44:37',
                id: 'aB93S0000000FTqSAM'
              }
            },
            record: {
              hasErrors: false
            }
          }.to_json
        end
        let(:mock_success_response) { MockFaradayResponse.new(response_body, 201) }

        before do
          Flipper.disable(:cg_OAuth_2_enabled)
        end

        it 'calls perform with expected params' do
          expect(client).to receive(:perform)
            .with(:post, resource, payload.to_json, exp_headers, { timeout: })
            .and_return(mock_success_response)

          expect(Rails.logger).to receive(:info).with("[Form 10-10CG] Submitting to '#{resource}'")
          expect(Rails.logger).to receive(:info)
            .with("[Form 10-10CG] Submission to '#{resource}' resource resulted in response code 201")
          expect(Sentry).to receive(:set_extras).with(response_body: mock_success_response.body)

          subject
        end

        context 'with a records error' do
          it 'raises RecordParseError' do
            expect(client).to receive(:do_post).with(resource, {}, 60).and_return(
              { 'data' => { 'carmacase' => { 'createdAt' => '2022-08-04 16:44:37', 'id' => 'aB93S0000000FTqSAM' } },
                'record' => { 'hasErrors' => true,
                              'results' => [{ 'referenceId' => '1010CG', 'id' => '0683S000000YBIFQA4',
                                              'errors' => [] }] } }
            )
            expect do
              subject
            end.to raise_error(CARMA::Client::MuleSoftClient::RecordParseError)
          end
        end
      end
    end
  end
end
