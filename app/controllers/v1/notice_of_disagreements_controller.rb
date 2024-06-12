# frozen_string_literal: true

module V1
  class NoticeOfDisagreementsController < AppealsBaseControllerV1
    include NoticeOfDisagreement::SubmitNod
    service_tag 'board-appeal'

    def show
      render json: decision_review_service.get_notice_of_disagreement(params[:id]).body
    rescue => e
      handle_exception(method: 'show', exception: e, options: { id: params[:id] })
      raise
    end

    def create
      raise 'Must pass in a version of the DecisionReview Service' if decision_review_service.nil?

      submit_nod # app/controllers/concerns/notice_of_disagreement/submit_nod.rb
      render json: nod_response_body
    rescue => e
      request = begin
        { body: request_body_hash }
      rescue
        request_body_debug_data
      end
      handle_exception(method: 'create', exception: e, options: { request: })
      raise
    end

    private

    def handle_exception(method:, exception:, options:)
      error_class = "#{self.class.name}##{method} exception #{exception.class} (NOD_V1)"
      log_exception_to_personal_information_log(exception, error_class:, **options)
    end

    def version_number
      'v2'
    end
  end
end
