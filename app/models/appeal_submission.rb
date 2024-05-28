# frozen_string_literal: true

class AppealSubmission < ApplicationRecord
  APPEAL_TYPES = %w[HLR NOD SC].freeze
  validates :user_uuid, :submitted_appeal_uuid, presence: true
  belongs_to :user_account, dependent: nil, optional: true
  validates :type_of_appeal, inclusion: APPEAL_TYPES

  has_kms_key
  has_encrypted :upload_metadata, key: :kms_key, **lockbox_options

  has_many :appeal_submission_uploads, dependent: :destroy

  def enqueue_uploads(uploads_arr, _user, version_number)
    uploads_arr.each do |upload_attrs|
      asu = AppealSubmissionUpload.create!(decision_review_evidence_attachment_guid: upload_attrs['confirmationCode'],
                                           appeal_submission_id: id)
      StatsD.increment("nod_evidence_upload.#{version_number}.queued")
      DecisionReview::SubmitUpload.perform_async(asu.id)
    end
  end
end
