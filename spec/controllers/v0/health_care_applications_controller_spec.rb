# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V0::HealthCareApplicationsController, type: :controller do
  let(:hca_request) { file_fixture('forms/healthcare_application_request.json').read }
  let(:hca_response) { JSON.parse(file_fixture('forms/healthcare_application_response.json').read) }

  describe '#create' do
    it 'creates a pending application' do
      post :create, params: JSON.parse(hca_request)

      json = JSON.parse(response.body)
      expect(json['attributes']).to eq(hca_response['attributes'])
    end
  end

  describe '#facilities' do
    let(:lighthouse_service) { instance_double(Lighthouse::Facilities::V1::Client) }
    let(:unrelated_facility) { OpenStruct.new(id: 'vha_123') }
    let(:target_facility) { OpenStruct.new(id: 'vha_456ab') }
    let(:facilities) { [unrelated_facility, target_facility] }

    before do
      allow(Lighthouse::Facilities::V1::Client).to receive(:new) { lighthouse_service }
      allow(lighthouse_service).to receive(:get_facilities) { facilities }
    end

    it 'retrieves facilities from Lighthouse' do
      state_params = { state: 'AK' }

      StdInstitutionFacility.create(station_number: '456ab')
      get :facilities, params: state_params

      expect(response.body).to eq(facilities.to_json)
    end

    context 'ves_active flag enabled' do
      it 'only returns facilities in VES' do
        params = { state: 'AK', ves_active: true }

        StdInstitutionFacility.create(station_number: '456ab')

        get(:facilities, params:)

        expect(response.body).to eq([target_facility].to_json)
      end

      it 'filters out deactivated facilities' do
        params = { state: 'AK', ves_active: true }

        StdInstitutionFacility.create(station_number: '456ab', deactivation_date: Time.current)

        get(:facilities, params:)

        expect(response.body).to eq({ data: [] }.to_json)
      end
    end
  end
end
