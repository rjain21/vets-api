# frozen_string_literal: true

module V0
  module Profile
    class ContactInformationsController < ApplicationController
      include Vet360::Writeable
      service_tag 'profile'

      before_action { authorize :vet360, :access? }
      after_action :invalidate_cache

      def create
        write_to_vet360_and_render_transaction!(
          'contact-information',
          contact_information_params
        )
        Rails.logger.warn('ContactInformationsController#create request completed', sso_logging_info)
      end

      def create_or_update
        write_to_vet360_and_render_transaction!(
          'contact-information',
          contact_information_params,
          http_verb: 'update'
        )
      end

      def update
        write_to_vet360_and_render_transaction!(
          'contact-information',
          contact_information_params,
          http_verb: 'put'
        )
        Rails.logger.warn('ContactInformationsController#update request completed', sso_logging_info)
      end

      def destroy
        write_to_vet360_and_render_transaction!(
          'contact-information',
          add_effective_end_date(contact_information_params),
          http_verb: 'put'
        )
        Rails.logger.warn('ContactInformationsController#destroy request completed', sso_logging_info)
      end

      private

      def contact_information_params
        params.permit(
          addresses: [
            :address_line1,
            :address_line2,
            :address_line3,
            :address_pou,
            :address_type,
            :city,
            :country_code_iso3,
            :county_code,
            :county_name,
            :validation_key,
            :id,
            :international_postal_code,
            :province,
            :state_code,
            :transaction_id,
            :zip_code,
            :zip_code_suffix,
            :source_date  # TODO why isn't this set programmatically?
          ],
          telephones: [
            :area_code,
            :country_code,
            :extension,
            :id,
            :is_international,
            :is_textable,
            :is_text_permitted,
            :is_tty,
            :is_voicemailable,
            :phone_number,
            :phone_type,
            :transaction_id
          ],
          emails: [
            :email_address,
            :id,
            :transaction_id
          ]
        )
      end

    end
  end
end
