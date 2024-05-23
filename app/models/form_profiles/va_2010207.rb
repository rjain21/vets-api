# frozen_string_literal: true

class FormProfiles::VA2010207 < FormProfile
  def carryover
    @identity_information = initialize_identity_information
    @contact_information = initialize_contact_information
    @military_information = initialize_military_information

    mappings = self.class.mappings_for_form('21-4138')
    form_data = generate_prefill(mappings)

    { form_data:, metadata: }
  end
end
