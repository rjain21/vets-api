module NoticeOfDisagreement
  module SubmitNod
    extend ActiveSupport::Concern

    def submit_nod
      ActiveRecord::Base.transaction do
        InProgressForm.form_for_user('10182', @current_user)&.destroy!
        enqueue_uploads
      end
    end

    private

    def enqueue_uploads
      uploads_arr = request_body_hash.delete('nodUploads') || []
      appeal_submission.enqueue_uploads(uploads_arr, @current_user, version_number)
    end

    def appeal_submission
      @appeal_submission ||= AppealSubmission.create!(appeal_submission_params)
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

  end
end
