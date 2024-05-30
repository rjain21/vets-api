# frozen_string_literal: true

require 'rails_helper'
require Rails.root / 'modules/claims_api/spec/rails_helper'

RSpec.describe 'VeteranRepresentative versus POARequest comparison', :bgs do # rubocop:disable RSpec/DescribeClass
  # Can regenerate live results by deleting the `results.json` file and
  # `results.yml` cassette file.
  #
  # Can remove this if we produce more focused tests that compare the state of
  # the data in various scenarios.
  it 'concerns the same underlying data' do # rubocop:disable RSpec/NoExpectationExample
    use_soap_cassette('results', use_spec_name_prefix: true) do
      comparisons = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = {} } }

      page_number = 1
      page_size = 100

      exceptional_participant_ids = Set[
        '13397031',
        '111'
      ]

      search_action =
        ClaimsApi::BGSClient::Definitions::
          ManageRepresentativeService::
          ReadPoaRequest::DEFINITION.name

      loop do
        poa_requests = search_poa_requests(page_number, page_size)
        poa_requests.each do |poa_request|
          participant_id = poa_request['vetPtcpntID']
          next if participant_id.in?(exceptional_participant_ids)
          next if participant_id.blank?

          proc_id = poa_request['procID']
          comparisons[participant_id][proc_id][search_action] = poa_request
        end

        break if poa_requests.size < page_size

        page_number += 1
      end

      veteran_representative_action =
        ClaimsApi::BGSClient::Definitions::
          VeteranRepresentativeService::
          ReadAllVeteranRepresentatives::DEFINITION.name

      poa_request_action =
        ClaimsApi::BGSClient::Definitions::
          ManageRepresentativeService::
          ReadPoaRequestByParticipantId::DEFINITION.name

      comparisons.each_key do |participant_id|
        veteran_representatives = get_veteran_representatives(participant_id)
        veteran_representatives.each do |veteran_representative|
          next if veteran_representative['secondaryStatus'].to_s.strip.downcase == 'obsolete'
          next unless veteran_representative['vdcStatus'].to_s.strip.downcase == 'submitted'

          proc_id = veteran_representative['procId']
          comparisons[participant_id][proc_id][veteran_representative_action] = veteran_representative
        end

        poa_requests = get_poa_requests(participant_id)
        poa_requests.each do |poa_request|
          proc_id = poa_request['procID']
          comparisons[participant_id][proc_id][poa_request_action] = poa_request
        end
      end

      records = comparisons.values.flat_map(&:values)
      categories = records.group_by(&:keys)
      tally = categories.transform_values(&:size)
      expect(tally).to eq(
        ['readPOARequest', 'readAllVeteranRepresentatives'] => 29,
        ['readPOARequest', 'readAllVeteranRepresentatives', 'readPOARequestByPtcpntId'] => 51,
        ['readPOARequest', 'readPOARequestByPtcpntId'] => 5
      )
    end
  end

  def search_poa_requests(page_number, page_size) # rubocop:disable Metrics/MethodLength
    poa_codes = %w[
      002 003 004 005 006 007 008 009 00V 010 012 014 015 016 017 018 019 020
      021 022 023 025 027 028 030 031 032 033 034 035 036 037 038 039 040 041
      043 044 045 046 047 048 049 050 051 052 054 055 056 059 060 064 065 070
      071 073 074 075 077 078 079 080 081 082 083 084 085 086 087 088 090 091
      093 094 097 095 097 1EY 4R0 4R2 4R3 6B6 862 869 8FE 9U7 BQX E5L FYT HTC
      HW0 IP4 J3C JCV
    ]

    action =
      ClaimsApi::BGSClient::Definitions::
        ManageRepresentativeService::
        ReadPoaRequest::DEFINITION

    result =
      ClaimsApi::BGSClient.perform_request(action) do |xml, data_aliaz|
        xml[data_aliaz].POACodeList do
          poa_codes.each do |poa_code|
            xml.POACode(poa_code)
          end
        end

        xml[data_aliaz].SecondaryStatusList do
          xml.SecondaryStatus('New')
          xml.SecondaryStatus('Pending')
          xml.SecondaryStatus('Accepted')
          xml.SecondaryStatus('Declined')
        end

        xml[data_aliaz].POARequestParameter do
          xml.pageIndex(page_number)
          xml.pageSize(page_size)
        end
      end

    Array.wrap(result['poaRequestRespondReturnVOList'])
  end

  def get_poa_requests(participant_id)
    action =
      ClaimsApi::BGSClient::Definitions::
        ManageRepresentativeService::
        ReadPoaRequestByParticipantId::DEFINITION

    result =
      ClaimsApi::BGSClient.perform_request(action) do |xml|
        xml.PtcpntId(participant_id)
      end

    Array.wrap(result['poaRequestRespondReturnVOList'])
  end

  def get_veteran_representatives(participant_id)
    action =
      ClaimsApi::BGSClient::Definitions::
        VeteranRepresentativeService::
        ReadAllVeteranRepresentatives::DEFINITION

    result =
      ClaimsApi::BGSClient.perform_request(action) do |xml, data_aliaz|
        xml[data_aliaz].CorpPtcpntIdFormTypeCode do
          xml.formTypeCode('21-22')
          xml.veteranCorpPtcpntId(participant_id)
        end
      end

    Array.wrap(result)
  end
end
