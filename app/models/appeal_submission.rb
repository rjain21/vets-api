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

# => [{"name"=>"my_file.pdf", "confirmationCode"=>"aaad6f52-2e85-43d4-a5a3-1d9cb4e482a0"}]



# ================================================================================
# An HTTP request has been made that VCR does not know how to handle:
#   POST https://sandbox-api.va.gov/services/appeals/v1/decision_reviews/notice_of_disagreements

# VCR is currently using the following cassette:
#   - /Users/steven.cumming/workspace/va.gov/vets-api/spec/support/vcr_cassettes/decision_review/NOD-CREATE-RESPONSE-200.yml
#     - :record => :once
#     - :match_requests_on => [:method, :uri]

# Under the current configuration VCR can not find a suitable HTTP interaction
# to replay and is prevented from recording new requests. There are a few ways
# you can deal with this:

#   * If you're surprised VCR is raising this error
#     and want insight about how VCR attempted to handle the request,
#     you can use the debug_logger configuration option to log more details [1].
#   * You can use the :new_episodes record mode to allow VCR to
#     record this new request to the existing cassette [2].
#   * If you want VCR to ignore this request (and others like it), you can
#     set an `ignore_request` callback [3].
#   * The current record mode (:once) does not allow new requests to be recorded
#     to a previously recorded cassette. You can delete the cassette file and re-run
#     your tests to allow the cassette to be recorded with this request [4].
#   * The cassette contains an HTTP interaction that matches this request,
#     but it has already been played back. If you wish to allow a single HTTP
#     interaction to be played back multiple times, set the `:allow_playback_repeats`
#     cassette option [5].

# [1] https://www.relishapp.com/vcr/vcr/v/6-2-0/docs/configuration/debug-logging
# [2] https://www.relishapp.com/vcr/vcr/v/6-2-0/docs/record-modes/new-episodes
# [3] https://www.relishapp.com/vcr/vcr/v/6-2-0/docs/configuration/ignore-request
# [4] https://www.relishapp.com/vcr/vcr/v/6-2-0/docs/record-modes/once
# [5] https://www.relishapp.com/vcr/vcr/v/6-2-0/docs/request-matching/playback-repeats
# ================================================================================
