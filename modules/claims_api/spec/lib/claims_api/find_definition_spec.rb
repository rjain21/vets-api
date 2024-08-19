# frozen_string_literal: true

require 'rails_helper'
require 'bgs_service/local_bgs_refactored/find_definition'

describe ClaimsApi::LocalBGSRefactored::FindDefinition do
  subject { described_class }

  before do
    Flipper.disable(:lighthouse_claims_api_hardcode_wsdl)
  end

  describe '#for_action' do
    context 'hardcoded WSDL' do
      before do
        Flipper.enable(:lighthouse_claims_api_hardcode_wsdl)
      end

      context 'OrgWebServiceBean' do
        let(:endpoint) { 'OrgWebServiceBean/OrgWebService' }
        let(:action) { 'findPoaHistoryByPtcpntId' }
        let(:key) { 'PoaHistory' }

        it 'response with the correct attributes' do
          result = subject.for_action(endpoint, action)
          parsed_result = JSON.parse(result.to_json)
          expect(parsed_result['service']['bean']['path']).to eq 'OrgWebServiceBean'
          expect(parsed_result['service']['path']).to eq 'OrgWebService'
          expect(parsed_result['service']['bean']['namespaces']['target']).to eq 'http://org.services.vetsnet.vba.va.gov/'
        end
      end

      # This one doesn't have `Bean` at the end
      context 'TrackedItemService' do
        let(:endpoint) { 'TrackedItemService/TrackedItemService' }
        let(:action) { 'findTrackedItems' }
        let(:key) { 'BenefitClaim' }

        it 'response with the correct attributes' do
          result = subject.for_action(endpoint, action)
          parsed_result = JSON.parse(result.to_json)
          expect(parsed_result['service']['bean']['path']).to eq 'TrackedItemService'
          expect(parsed_result['service']['path']).to eq 'TrackedItemService'
          expect(parsed_result['service']['bean']['namespaces']['target']).to eq 'http://services.mapd.benefits.vba.va.gov/'
        end
      end
    end
  end

  describe '#for_service' do
    context 'hardcoded WSDL' do
      before do
        Flipper.enable(:lighthouse_claims_api_hardcode_wsdl)
      end

      context 'OrgWebService' do
        let(:endpoint) { 'OrgWebServiceBean/OrgWebService' }

        it 'response with the correct namespace' do
          result = subject.for_service(endpoint)
          parsed_result = JSON.parse(result.to_json)
          expect(parsed_result['bean']['path']).to eq 'OrgWebServiceBean'
          expect(parsed_result['path']).to eq 'OrgWebService'
          expect(parsed_result['bean']['namespaces']['target']).to eq 'http://org.services.vetsnet.vba.va.gov/'
        end
      end

      context 'TrackedItemService' do
        let(:endpoint) { 'TrackedItemService/TrackedItemService' }

        it 'response with the correct namespace' do
          result = subject.for_service(endpoint)
          parsed_result = JSON.parse(result.to_json)
          expect(parsed_result['bean']['path']).to eq 'TrackedItemService'
          expect(parsed_result['path']).to eq 'TrackedItemService'
          expect(parsed_result['bean']['namespaces']['target']).to eq 'http://services.mapd.benefits.vba.va.gov/'
        end
      end
    end
  end
end
