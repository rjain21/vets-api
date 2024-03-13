# frozen_string_literal: true

module SimpleFormsApi
  class VBA210972
    include Virtus.model(nullify_blank: true)

    attribute :data

    def initialize(data)
      @data = data
    end

    def metadata
      {
        'veteranFirstName' => @data.dig('veteran_full_name', 'first'),
        'veteranLastName' => @data.dig('veteran_full_name', 'last'),
        'fileNumber' => @data['veteran_va_file_number'].presence || @data['veteran_ssn'],
        'zipCode' => @data.dig('preparer_address', 'postal_code') || '00000',
        'source' => 'VA Platform Digital Forms',
        'docType' => @data['form_number'],
        'businessLine' => 'CMP'
      }
    end

    def submission_date_config
      {
        should_stamp_date?: true,
        page_number: 1,
        title_coords: [440, 690],
        text_coords: [440, 670]
      }
    end

    def track_user_identity(confirmation_number); end
  end
end
