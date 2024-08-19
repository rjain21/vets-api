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

      context 'EBenefitsBnftClaimStatusWebServiceBean' do
        let(:endpoint) { 'EBenefitsBnftClaimStatusWebServiceBean/EBenefitsBnftClaimStatusWebService' }
        let(:action) { 'findBenefitClaimsStatusByPtcpntId' }
        let(:key) { 'BenefitClaimsDTO' }

        it 'response with the correct attributes' do
          result = subject.for_action(endpoint, action)
          parsed_result = JSON.parse(result.to_json)
          expect(parsed_result['service']['bean']['path']).to eq 'EBenefitsBnftClaimStatusWebServiceBean'
          expect(parsed_result['service']['path']).to eq 'EBenefitsBnftClaimStatusWebService'
          expect(parsed_result['service']['bean']['namespaces']['target']).to eq 'http://claimstatus.services.ebenefits.vba.va.gov/'
        end
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
    end
  end

  describe '#for_service' do
    context 'hardcoded WSDL' do
      before do
        Flipper.enable(:lighthouse_claims_api_hardcode_wsdl)
      end

      context 'EBenefitsBenefitClaimStatusWebService' do
        let(:endpoint) { 'EBenefitsBnftClaimStatusWebServiceBean/EBenefitsBnftClaimStatusWebService' }

        it 'response with the correct namespace' do
          result = subject.for_service(endpoint)
          parsed_result = JSON.parse(result.to_json)
          expect(parsed_result['bean']['path']).to eq 'EBenefitsBnftClaimStatusWebServiceBean'
          expect(parsed_result['path']).to eq 'EBenefitsBnftClaimStatusWebService'
          expect(parsed_result['bean']['namespaces']['target']).to eq 'http://claimstatus.services.ebenefits.vba.va.gov/'
        end
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
    end
  end
end
