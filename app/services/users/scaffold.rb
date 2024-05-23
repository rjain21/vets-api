# frozen_string_literal: true

module Users
  # Struct class serving as the pre-serialized object that is passed to the UserSerializer
  # during the '/v0/user' endpoint call.
  #
  # Note that with Struct's, parameter order matters.  Namely having `errors` first
  # and `status` second.
  #
  # rubocop:disable Style/StructInheritance
  class Scaffold < Struct.new(:account, :carryovers_available, :errors, :in_progress_forms, :onboarding,
                              :prefills_available, :profile, :services, :session, :status, :va_profile,
                              :vet360_contact_information, :veteran_status)
  end
  # rubocop:enable Style/StructInheritance
end
