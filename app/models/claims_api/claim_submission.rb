# frozen_string_literal: true

module ClaimsApi
  class ClaimSubmission < LHDIApplicationRecord
    validates :claim_type, presence: true
    validates :consumer_label, presence: true

    belongs_to :claim, class_name: 'AutoEstablishedClaim'
  end
end
