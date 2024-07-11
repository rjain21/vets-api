class FormSubmissionsController < ApplicationController
  skip_before_action :authenticate

  def index
    if params[:benefits_intake_uuid].present?
      @form_submissions = FormSubmission.where(benefits_intake_uuid: params[:benefits_intake_uuid])
      
      # Extract and decrypt form_data for each form submission
      form_data_list = @form_submissions.map do |form_submission|
        {
          id: form_submission.id,
          form_data: ActiveSupport::JSON.decode(form_submission.form_data)
        }
      end

      render json: form_data_list
    else
      render json: { error: "Benefits parameter is required" }, status: :bad_request
    end
  end
end
