# frozen_string_literal: true

class AppealSubmission < ApplicationRecord
  APPEAL_TYPES = %w[HLR NOD SC].freeze
  validates :user_uuid, :submitted_appeal_uuid, presence: true
  belongs_to :user_account, dependent: nil, optional: true
  validates :type_of_appeal, inclusion: APPEAL_TYPES

  has_kms_key
  has_encrypted :upload_metadata, key: :kms_key, **lockbox_options

  has_many :appeal_submission_uploads, dependent: :destroy
end
