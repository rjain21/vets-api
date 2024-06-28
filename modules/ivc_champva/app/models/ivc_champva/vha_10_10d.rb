# frozen_string_literal: true

module IvcChampva
  class VHA1010d
    ADDITIONAL_PDF_KEY = 'applicants'
    ADDITIONAL_PDF_COUNT = 3
    STATS_KEY = 'api.ivc_champva_form.10_10d'

    include Virtus.model(nullify_blank: true)
    include Attachments

    attribute :data
    attr_reader :form_id

    def initialize(data)
      @data = data
      @uuid = SecureRandom.uuid
      @form_id = 'vha_10_10d'
    end

    def metadata
      {
        'veteranFirstName' => @data.dig('veteran', 'full_name', 'first'),
        'veteranMiddleName' => @data.dig('veteran', 'full_name', 'middle'),
        'veteranLastName' => @data.dig('veteran', 'full_name', 'last'),
        'sponsorFirstName' => @data.fetch('applicants', [])&.first&.dig('full_name', 'first'),
        'sponsorMiddleName' => @data.fetch('applicants', [])&.first&.dig('full_name', 'middle'),
        'sponsorLastName' => @data.fetch('applicants', [])&.first&.dig('full_name', 'last'),
        'fileNumber' => @data.dig('veteran', 'va_claim_number').presence || @data.dig('veteran', 'ssn_or_tin'),
        'zipCode' => @data.dig('veteran', 'address', 'postal_code') || '00000',
        'country' => @data.dig('veteran', 'address', 'country') || 'USA',
        'source' => 'VA Platform Digital Forms',
        'docType' => @data['form_number'],
        'businessLine' => 'CMP',
        'ssn_or_tin' => @data.dig('veteran', 'ssn_or_tin'),
        'uuid' => @uuid,
        'primaryContactInfo' => @data['primary_contact_info']
      }
    end

    def submission_date_config
      { should_stamp_date?: false }
    end

    def track_user_identity
      identity = data['certifier_role']
      StatsD.increment("#{STATS_KEY}.#{identity}")
      Rails.logger.info('IVC ChampVA Forms - 10-10D Submission User Identity', identity:)
    end

    def method_missing(_, *args)
      args&.first
    end

    def respond_to_missing?(_)
      true
    end
  end
end
