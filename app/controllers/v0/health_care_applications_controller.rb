# frozen_string_literal: true

module V0
  class HealthCareApplicationsController < ApplicationController
    skip_before_action(:authenticate)
    before_action(:tag_rainbows)

    def create
      authenticate_token

      health_care_application = HealthCareApplication.new(params.permit(:form))
      health_care_application.async_compatible = params[:async_compatible]
      health_care_application.user = current_user

      result = health_care_application.process!

      clear_saved_form(HealthCareApplication::FORM_ID)

      render(json: result)
    end

    def healthcheck
      render(json: HCA::Service.new.health_check)
    end

    private

    def skip_sentry_exception_types
      super + [Common::Exceptions::GatewayTimeout, Common::Exceptions::BackendServiceException]
    end
  end
end
