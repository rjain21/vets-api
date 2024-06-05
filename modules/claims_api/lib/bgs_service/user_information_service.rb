# frozen_string_literal: true

require 'bgs_service/vnp_proc_service_v2'
require_relative 'veteran_representative_service'

module ClaimsApi
  class UserInformationService < ClaimsApi::LocalBGS
    # vnp_proc_id: VNP Proc ID to find by
    def find_by_data_supplied(vnp_proc_id)
      arg_strg = convert_nil_values({ vnp_proc_id:, user_identity_type: nil, user_identity_value: nil,
                                      vnp_proc_state_type_cd: nil })
      body = Nokogiri::XML::DocumentFragment.parse <<~EOXML
        <data:UserInformationInput>#{arg_strg}</data:UserInformationInput>
      EOXML

      make_request(endpoint: 'VDC/UserInformationServiceV2',
                   action: 'findByDataSupplied', body:,
                   namespaces: { 'data' => '/userinformation/data' })[:user_information_service_return]
    end
  end
end
