# frozen_string_literal: true

require 'iso_country_codes'

class FormProfiles::VA21p530v2 < FormProfile
  def metadata
    {
      version: 0,
      prefill: true,
      returnUrl: '/claimant-information'
    }
  end

  def prefill
    @identity_information = initialize_identity_information
    @contact_information = initialize_contact_information
    @military_information = initialize_military_information
    if @contact_information&.address&.country.present?
      @contact_information.address.country = convert_to_iso2(@contact_information.address.country)
    end
    binding.pry
    custom_prefills
    mappings = self.class.mappings_for_form(form_id)
    form_data = generate_prefill(mappings) if FormProfile.prefill_enabled_forms.include?(form_id)

    { form_data:, metadata: }
  end

  private

  def convert_to_iso2(country_code)
    code = IsoCountryCodes.find(country_code)
    code.alpha2
  end

  def custom_prefills
    unless @contact_information.email
      @contact_information.email = user.email
    end

  end
end
