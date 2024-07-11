# frozen_string_literal: true

module V0
  class VeteranReadinessEmploymentClaimsController < ClaimsBaseController
    service_tag 'vre-application'
    before_action :authenticate
    skip_before_action :load_user

    def create
      binding.pry
      claim = SavedClaim::VeteranReadinessEmploymentClaim.new(form: filtered_params[:form],
                                                              user_account_id: current_user&.user_account_uuid)
      binding.pry
      if claim.save
        VRE::Submit1900Job.perform_async(claim.id, current_user.uuid)
        Rails.logger.info "ClaimID=#{claim.confirmation_number} Form=#{claim.class::FORM}"
        clear_saved_form(claim.form_id)
        render json: claim
      else
        StatsD.increment("#{stats_key}.failure")
        Sentry.set_tags(team: 'vfs-ebenefits') # tag sentry logs with team name
        Rails.logger.error('VR&E claim was not saved', { error_messages: claim.errors,
                                                         user_logged_in: current_user.present?,
                                                         current_user_uuid: current_user&.uuid })
        raise Common::Exceptions::ValidationErrors, claim
      end
    end

    private

    def filtered_params
      params.require(:veteran_readiness_employment_claim).permit(:form)
    end

    def short_name
      'veteran_readiness_employment_claim'
    end
  end
end
