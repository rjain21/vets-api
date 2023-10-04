# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/helpers/sis_session_helper'

RSpec.describe 'check in demographics', type: :request do
  let!(:user) do
    sis_user(
      icn: '24811694708759028',
      vha_facility_hash: {
        '516' => ['12345'],
        '553' => ['2'],
        '200HD' => ['12345'],
        '200IP' => ['TKIP123456'],
        '200MHV' => ['123456']
      },
      vha_facility_ids: %w[516 553 200HD 200IP 200MHV]
    )
  end

  describe 'GET /mobile/v0/appointments/check-in/demographics' do
    context 'test' do
      it 'returns expected check in demographics data' do
        VCR.use_cassette('mobile/check_in/token_200') do
          VCR.use_cassette('mobile/check_in/get_demographics_200') do
            get '/mobile/v0/appointments/check-in/demographics', headers: sis_headers,
                                                                 params: { 'location_id' => '516' }
          end
        end
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          { 'data' =>
             { 'id' => user.uuid,
               'type' => 'checkInDemographics',
               'attributes' =>
                { 'insuranceVerificationNeeded' => false,
                  'needsConfirmation' => true,
                  'mailingAddress' =>
                   { 'street1' => 'Any Street',
                     'street2' => '',
                     'street3' => '',
                     'city' => 'Any Town',
                     'county' => '',
                     'state' => 'WV',
                     'zip' => '999980071',
                     'zip4' => nil,
                     'country' => 'USA' },
                  'residentialAddress' =>
                   { 'street1' => '186 Columbia Turnpike',
                     'street2' => '',
                     'street3' => '',
                     'city' => 'Florham Park',
                     'county' => '',
                     'state' => 'New Mexico',
                     'zip' => '07932',
                     'zip4' => nil,
                     'country' => 'USA' },
                  'homePhone' => '222-555-8235',
                  'officePhone' => '222-555-7720',
                  'cellPhone' => '315-378-9190',
                  'email' => 'payibo6648@weishu8.com',
                  'emergencyContact' =>
                   { 'name' => 'Bryant Richard',
                     'relationship' => 'Brother',
                     'phone' => '310-399-2006',
                     'workPhone' => '708-391-9015',
                     'address' =>
                      { 'street1' => '690 Holcomb Bridge Rd',
                        'street2' => '',
                        'street3' => '',
                        'city' => 'Roswell',
                        'county' => '',
                        'state' => 'Georgia',
                        'zip' => '30076',
                        'zip4' => '',
                        'country' => 'USA' },
                     'needsConfirmation' => true },
                  'nextOfKin' => { 'name' => nil,
                                   'relationship' => nil,
                                   'phone' => nil,
                                   'workPhone' => nil,
                                   'address' =>
                                     { 'street1' => nil,
                                       'street2' => nil,
                                       'street3' => nil,
                                       'city' => nil,
                                       'county' => nil,
                                       'state' => nil,
                                       'zip' => nil,
                                       'zip4' => nil,
                                       'country' => nil },
                                   'needsConfirmation' => true } } } }
        )
      end
    end

    context 'When upstream service returns 500' do
      it 'returns expected error' do
        VCR.use_cassette('mobile/check_in/token_200') do
          VCR.use_cassette('mobile/check_in/get_demographics_500') do
            get '/mobile/v0/appointments/check-in/demographics', headers: sis_headers,
                                                                 params: { 'location_id' => '516' }
          end
        end
        expect(response).to have_http_status(:bad_gateway)
        expect(response.parsed_body).to eq({ 'errors' =>
                                  [{ 'title' => 'Bad Gateway',
                                     'detail' =>
                                      'Received an an invalid response from the upstream server',
                                     'code' => 'MOBL_502_upstream_error',
                                     'status' => '502' }] })
      end
    end
  end

  describe 'PATCH /mobile/v0/appointments/check-in/demographics' do
    context 'when upstream updates successfully' do
      it 'returns demographic confirmations' do
        VCR.use_cassette('mobile/check_in/token_200') do
          VCR.use_cassette('mobile/check_in/update_demographics_200') do
            patch '/mobile/v0/appointments/check-in/demographics',
                  headers: sis_headers,
                  params: { 'location_id' => '418',
                            'demographic_confirmations' => { 'contact_needs_update' => false,
                                                             'emergency_contact_needs_update' => true,
                                                             'next_of_kin_needs_update' => false } }
          end
        end
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          { 'data' =>
              { 'id' => '5',
                'type' => 'demographicConfirmations',
                'attributes' =>
                  { 'contactNeedsUpdate' => false,
                    'emergencyContactNeedsUpdate' => true,
                    'nextOfKinNeedsUpdate' => false } } }
        )
      end
    end

    context 'when upstream service fails' do
      it 'throws an exception' do
        VCR.use_cassette('mobile/check_in/token_200') do
          VCR.use_cassette('mobile/check_in/update_demographics_500') do
            patch '/mobile/v0/appointments/check-in/demographics',
                  headers: sis_headers,
                  params: { 'location_id' => '418',
                            'demographic_confirmations' => { 'contact_needs_update' => false,
                                                             'emergency_contact_needs_update' => true,
                                                             'next_of_kin_needs_update' => false } }
          end
        end
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq(
          { 'errors' =>
              [
                { 'title' => 'Operation failed',
                  'detail' => 'The upstream server returned an error code that is unmapped',
                  'code' => 'unmapped_service_exception',
                  'status' => '400' }
              ] }
        )
      end
    end
  end
end
