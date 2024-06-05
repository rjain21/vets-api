# frozen_string_literal: true

module ClaimsApi
  class VnpProcFormService < ClaimsApi::LocalBGS
    FORM_TYPE_CD = '21-22'

    # vnp_proc_id: VNP Proc ID to find by
    def vpn_proc_form_find_by_primary_key(vnp_proc_id)
      arg_strg = convert_nil_values({ vnp_proc_id: })
      body = Nokogiri::XML::DocumentFragment.parse <<~EOXML
        <arg0>#{arg_strg}</arg0>
      EOXML

      make_request(endpoint: 'VnpProcFormWebServiceBean/VnpProcFormService',
                   action: 'vnpProcFormFindByPrimaryKey', body:)
    end

    def vnp_proc_form_create(options)
      vnp_proc_id = options[:vnp_proc_id]
      options.delete(:vnp_proc_id)
      arg_strg = convert_nil_values(options)
      body = Nokogiri::XML::DocumentFragment.parse <<~EOXML
        <arg0>
          <compId>
            <vnpProcId>#{vnp_proc_id}</vnpProcId>
            <formTypeCd>#{FORM_TYPE_CD}</formTypeCd>
          </compId>
        #{arg_strg}
        </arg0>
      EOXML

      make_request(endpoint: 'VnpProcFormWebServiceBean/VnpProcFormService',
                   action: 'vnpProcFormCreate', body:, key: 'return')
    end
  end
end
