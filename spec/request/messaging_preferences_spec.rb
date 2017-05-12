# frozen_string_literal: true
require 'rails_helper'
require 'sm/client'
require 'support/sm_client_helpers'

RSpec.describe 'messaging_preferences', type: :request do
  include SM::ClientHelpers

  let(:current_user) { build(:mhv_user) }

  before(:each) do
    allow(SM::Client).to receive(:new).and_return(authenticated_client)
    use_authenticated_current_user(current_user: current_user)
  end

  it 'responds to GET #show of preferences' do
    VCR.use_cassette('sm_client/preferences/fetches_email_settings_for_notifications') do
      get '/v0/messaging/health/preferences'
    end

    expect(response).to be_success
    expect(response.body).to be_a(String)
    attrs = JSON.parse(response.body)['data']['attributes']
    expect(attrs['email_address']).to eq('muazzam.khan@va.gov')
    expect(attrs['frequency']).to eq('daily')
  end

  it 'responds to PUT #update of preferences' do
    VCR.use_cassette('sm_client/preferences/sets_the_email_notification_settings', record: :none) do
      params = { email_address: 'kamyar.karshenas@va.gov',
                 frequency: 'none' }
      put '/v0/messaging/health/preferences', params
    end

    expect(response).to have_http_status(200)
    expect(JSON.parse(response.body)['data']['id'])
      .to eq('17126b0821ad0472ae11944e9861f82d6bdd17801433e200e6a760148a4866c3')
    expect(JSON.parse(response.body)['data']['attributes'])
      .to eq('email_address' => 'kamyar.karshenas@va.gov', 'frequency' => 'none')
  end

  it 'requires all parameters for update' do
    VCR.use_cassette('sm_client/preferences/sets_the_email_notification_settings', record: :none) do
      params = { email_address: 'kamyar.karshenas@va.gov' }
      put '/v0/messaging/health/preferences', params
    end

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'rejects unknown frequency parameters' do
    VCR.use_cassette('sm_client/preferences/sets_the_email_notification_settings', record: :none) do
      params = { email_address: 'kamyar.karshenas@va.gov',
                 frequency: 'hourly' }
      put '/v0/messaging/health/preferences', params
    end

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
