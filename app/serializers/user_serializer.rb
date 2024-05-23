# frozen_string_literal: true

require 'backend_services'
require 'common/client/concerns/service_status'

class UserSerializer < ActiveModel::Serializer
  include Common::Client::Concerns::ServiceStatus

  attributes :account, :carryovers_available, :in_progress_forms, :onboarding,
             :prefills_available, :profile, :services, :session, :va_profile,
             :vet360_contact_information, :veteran_status

  def id
    nil
  end

  delegate :account, to: :object
  delegate :carryovers_available, to: :object
  delegate :in_progress_forms, to: :object
  delegate :onboarding, to: :object
  delegate :prefills_available, to: :object
  delegate :profile, to: :object
  delegate :services, to: :object
  delegate :session, to: :object
  delegate :va_profile, to: :object
  delegate :vet360_contact_information, to: :object
  delegate :veteran_status, to: :object
end
