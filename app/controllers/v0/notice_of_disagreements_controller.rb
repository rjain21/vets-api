# frozen_string_literal: true

module V0
  class NoticeOfDisagreementsController < AppealsBaseController
    service_tag 'board-appeal'

    def create
      raise 'Must pass in a version of the DecisionReview Service' if decision_review_service.nil?

      ActiveRecord::Base.transaction do
        InProgressForm.form_for_user('10182', @current_user)&.destroy!
        enqueue_uploads
        render json: nod_response_body
      end
    rescue => e
      request = begin
        { body: request_body_hash }
      rescue
        request_body_debug_data
      end
      handle_exception(method: 'create', exception: e, options: { request: request })
      raise
    end

    def show
      render json: decision_review_service.get_notice_of_disagreement(params[:id]).body
    rescue => e
      handle_exception(method: 'show', exception: e, options: { id: params[:id] })
      raise
    end

    private

    def enqueue_uploads
      uploads_arr = request_body_hash.delete('nodUploads') || []
      appeal_submission.enqueue_uploads(uploads_arr, @current_user, 'v1')
    end

    def appeal_submission
      @appeal_submission ||= AppealSubmission.create(appeal_submission_params)
    end

    def appeal_submission_params
      {
        type_of_appeal: 'NOD',
        user_uuid: @current_user.uuid,
        user_account: @current_user.user_account,
        board_review_option: request_body_hash['data']['attributes']['boardReviewOption'],
        upload_metadata: decision_review_service.class.file_upload_metadata(@current_user),
        submitted_appeal_uuid: nod_response_body.dig('data', 'id')
      }
    end

    def nod_response_body
      @nod_response_body ||= decision_review_service.create_notice_of_disagreement(
        request_body: request_body_hash,
        user: @current_user
      ).body
    end

    def handle_exception(method:, exception:, options:)
      error_class = "#{self.class.name}##{method} exception #{exception.class} (NOD)"
      log_exception_to_personal_information_log(exception, error_class: error_class, **options)
    end
  end
end
