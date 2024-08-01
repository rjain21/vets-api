# frozen_string_literal: true

module Mobile
  module V0
    module Adapters
      class LighthouseDirectDeposit
        def parse(direct_deposit_info)
          JSON.parse({
            control_information: parse_control_information(direct_deposit_info.control_information),
            payment_account: parse_payment_account(direct_deposit_info.payment_account)
          }.to_json,
                     object_class: OpenStruct)
        end

        private

        def parse_control_information(account_control_info)
          {
            can_update_address: account_control_info&.dig('can_update_direct_deposit') || false,
            corp_avail_indicator: account_control_info&.dig('is_corp_available') || false,
            corp_rec_found_indicator: account_control_info&.dig('is_corp_rec_found') || false,
            has_no_bdn_payments_indicator: account_control_info&.dig('has_no_bdn_payments') || false,
            identity_indicator: account_control_info&.dig('has_identity') || false,
            is_competent_indicator: account_control_info&.dig('is_competent') || false,
            index_indicator: account_control_info&.dig('has_index') || false,
            no_fiduciary_assigned_indicator: account_control_info&.dig('has_no_fiduciary_assigned') || false,
            not_deceased_indicator: account_control_info&.dig('is_not_deceased') || false,
            can_update_payment: account_control_info&.dig('can_update_direct_deposit') || false
          }
        end

        def parse_payment_account(payment_account_info)
          {
            account_type: payment_account_info&.dig(:account_type),
            financial_institution_name: payment_account_info&.dig(:name),
            account_number: payment_account_info&.dig(:account_number),
            financial_institution_routing_number: payment_account_info&.dig(:routing_number)
          }
        end
      end
    end
  end
end
