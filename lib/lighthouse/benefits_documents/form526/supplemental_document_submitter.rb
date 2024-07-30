# frozen_string_literal: true

module BenefitsDocuments
  module Form526
    class SubmitLighthouseDocumentService
      def self.call(*)
        new(*).call
      end

      # add docstring
      def initialize(form526_submission: nil, document_type: nil, file_name: nil, file_body: nil)
        @form526_submission = form526_submission
        @document_type = document_type
        @file_name = file_name
        @file_body = file_body
      end

      def call
        lighthouse_document = LighthouseDocument.new(
          claim_id: @form526_submission.submitted_claim_id,
          participant_id: user.participant_id,
          document_type: @document_type,
          file_name: @file_name
        )

        raise Common::Exceptions::ValidationErrors, document_data unless lighthouse_document.valid?

        client = BenefitsDocuments::WorkerService.new(@user.icn)
        client.upload_document(@file_body, lighthouse_document)
      end

      private

      def user
        # Double check this
        @user ||= User.find(@form_526_submission.user_uuid)
      end
    end
  end
end
