# frozen_string_literal: true

require 'rails_helper'
require 'carma/client/mule_soft_auth_token_client'

class MockFaradayResponse
  attr_reader :body, :status

  def initialize(body, status = 200)
    @body = body
    @status = status
  end
end

describe CARMA::Client::MuleSoftAuthTokenClient do
  let(:client) { described_class.new }

  let(:config) { double('config') }
  let(:timeout) { 60 }
  let(:settings) do
    OpenStruct.new(
      token_url: 'my/token/url',
      client_id: 'id',
      client_secret: 'secret',
      timeout:
    )
  end

  before do
    allow(client).to receive(:config).and_return(config)
    allow(config).to receive_messages(timeout:, settings:)
  end

  describe '#new_bearer_token' do
    subject { client.new_bearer_token }

    let(:token_url) { 'oauth2/ause1x1h6Zit9ziQL0j6/v1/token' }
    let(:token_params) do
      URI.encode_www_form({
                            grant_type: 'client_credentials',
                            scope: 'DTCWriteResource'
                          })
    end

    let(:basic_auth) do
      Base64.urlsafe_encode64("#{config.settings.client_id}:#{config.settings.client_secret}")
    end

    let(:token_headers) do
      {
        'Authorization' => "Basic #{basic_auth}",
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    end

    let(:options) { { timeout: } }

    let(:access_token) { 'my-token' }
    let(:mock_token_response) { MockFaradayResponse.new({ access_token: }, 201) }

    context 'successfully gets token' do
      it 'calls perform with expected params' do
        expect(client).to receive(:perform)
          .with(:post, token_url, token_params, token_headers, options)
          .and_return(mock_token_response)

        subject
      end
    end

    context 'error getting token' do
      let(:mock_error_token_response) { MockFaradayResponse.new({ sad: true }, 500) }

      it 'raises error' do
        expect(client).to receive(:perform)
          .with(:post, token_url, token_params, token_headers, options)
          .and_return(mock_error_token_response)

        expect do
          subject
        end.to raise_error(CARMA::Client::MuleSoftAuthTokenClient::GetAuthTokenError)
      end
    end
  end
end
