# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../rails_helper'
require 'token_validation/v2/client'
require 'bgs_service/local_bgs'

RSpec.describe 'Power Of Attorney', type: :request do
  let(:veteran_id) { '1013062086V794840' }
  let(:appoint_organization_path) { "/services/claims/v2/veterans/#{veteran_id}/2122" }
  let(:validate2122_path) { "/services/claims/v2/veterans/#{veteran_id}/2122/validate" }
  let(:scopes) { %w[system/claim.write system/claim.read] }
  let(:individual_poa_code) { 'A1H' }
  let(:organization_poa_code) { '083' }
  let(:bgs_poa) { { person_org_name: "#{individual_poa_code} name-here" } }
  let(:local_bgs) { ClaimsApi::LocalBGS }

  describe 'PowerOfAttorney' do
    before do
      Veteran::Service::Representative.create!(representative_id: '67890', poa_codes: [organization_poa_code],
                                               first_name: 'George', last_name: 'Washington')
      Veteran::Service::Organization.create!(poa: organization_poa_code,
                                             name: "#{organization_poa_code} - DISABLED AMERICAN VETERANS")
    end

    describe 'submit2122' do
      b64_image = File.read('modules/claims_api/spec/fixtures/signature_b64.txt')
      let(:data) do
        {
          data: {
            attributes: {
              serviceOrganization: {
                poaCode: organization_poa_code.to_s
              },
              signatures: {
                veteran: b64_image,
                representative: b64_image
              }
            }
          }
        }
      end

      context 'CCG (Client Credentials Grant) flow' do
        context 'when provided' do
          context 'when valid' do
            it 'returns a 202' do
              mock_ccg(scopes) do |auth_header|
                expect_any_instance_of(local_bgs).to receive(:find_poa_by_participant_id)
                  .and_return(bgs_poa)
                allow_any_instance_of(local_bgs).to receive(:find_poa_history_by_ptcpnt_id)
                  .and_return({ person_poa_history: nil })

                post appoint_organization_path, params: data.to_json, headers: auth_header

                expect(response).to have_http_status(:accepted)
              end
            end
          end

          context 'when not valid' do
            it 'returns a 401' do
              post appoint_organization_path, params: data, headers: { 'Authorization' => 'Bearer HelloWorld' }

              expect(response).to have_http_status(:unauthorized)
            end
          end
        end
      end

      context 'scopes' do
        let(:invalid_scopes) { %w[system/526-pdf.override] }
        let(:poa_scopes) { %w[system/claim.write] }

        context 'POA organization' do
          it 'returns a 200 response when successful' do
            mock_ccg_for_fine_grained_scope(poa_scopes) do |auth_header|
              expect_any_instance_of(local_bgs).to receive(:find_poa_by_participant_id)
                .and_return(bgs_poa)
              allow_any_instance_of(local_bgs).to receive(:find_poa_history_by_ptcpnt_id)
                .and_return({ person_poa_history: nil })

              post appoint_organization_path, params: data.to_json, headers: auth_header

              expect(response).to have_http_status(:accepted)
            end
          end

          it 'returns a 401 unauthorized with incorrect scopes' do
            mock_ccg_for_fine_grained_scope(invalid_scopes) do |auth_header|
              post appoint_organization_path, params: data.to_json, headers: auth_header

              expect(response).to have_http_status(:unauthorized)
            end
          end
        end
      end
    end

    describe 'validate2122' do
      context 'CCG (Client Credentials Grant) flow' do
        context 'when provided' do
          context 'when valid' do
            context 'when the request data is not a valid json object' do
              let(:data) { '123abc' }

              it 'returns a meaningful 422' do
                mock_ccg(%w[claim.write claim.read]) do |auth_header|
                  detail = 'The request body is not a valid JSON object: '

                  post validate2122_path, params: data, headers: auth_header

                  response_body = JSON.parse(response.body)['errors'][0]

                  expect(response).to have_http_status(:unprocessable_entity)
                  expect(response_body['title']).to eq('Unprocessable entity')
                  expect(response_body['status']).to eq('422')
                  expect(response_body['detail']).to eq(detail)
                end
              end
            end

            context 'when the Veteran ICN is found in MPI' do
              context 'when the request data does not pass schema validation' do
                let(:request_body) do
                  Rails.root.join('modules', 'claims_api', 'spec', 'fixtures', 'v2', 'veterans',
                                  'power_of_attorney', '2122', 'invalid_schema.json').read
                end

                it 'returns a meaningful 422' do
                  mock_ccg(%w[claim.write claim.read]) do |auth_header|
                    detail = 'The property /serviceOrganization did not contain the required key poaCode'

                    post validate2122_path, params: request_body, headers: auth_header

                    response_body = JSON.parse(response.body)['errors'][0]

                    expect(response).to have_http_status(:unprocessable_entity)
                    expect(response_body['title']).to eq('Unprocessable entity')
                    expect(response_body['status']).to eq('422')
                    expect(response_body['detail']).to eq(detail)
                  end
                end
              end
            end

            context 'when the request data passes schema validation' do
              context 'when no representatives have the provided POA code' do
                let(:request_body) do
                  Rails.root.join('modules', 'claims_api', 'spec', 'fixtures', 'v2', 'veterans',
                                  'power_of_attorney', '2122', 'invalid_poa.json').read
                end

                it 'returns a meaningful 404' do
                  mock_ccg(%w[claim.write claim.read]) do |auth_header|
                    detail = 'Could not find an Organization with code: aaa'

                    post validate2122_path, params: request_body, headers: auth_header

                    response_body = JSON.parse(response.body)['errors'][0]

                    expect(response).to have_http_status(:not_found)
                    expect(response_body['title']).to eq('Resource not found')
                    expect(response_body['status']).to eq('404')
                    expect(response_body['detail']).to eq(detail)
                  end
                end
              end

              context 'when at least one representative has the provided POA code' do
                let(:request_body) do
                  Rails.root.join('modules', 'claims_api', 'spec', 'fixtures', 'v2', 'veterans',
                                  'power_of_attorney', '2122', 'valid.json').read
                end

                it 'returns 200' do
                  mock_ccg(%w[claim.write claim.read]) do |auth_header|
                    post validate2122_path, params: request_body, headers: auth_header

                    response_body = JSON.parse(response.body)['data']

                    expect(response).to have_http_status(:ok)
                    expect(response_body['type']).to eq('form/21-22/validation')
                    expect(response_body['attributes']['status']).to eq('valid')
                  end
                end
              end
            end
          end
        end

        context 'when not valid' do
          it 'returns a 401' do
            post validate2122_path, headers: { 'Authorization' => 'Bearer HelloWorld' }

            expect(response).to have_http_status(:unauthorized)
          end
        end
      end
    end
  end
end
