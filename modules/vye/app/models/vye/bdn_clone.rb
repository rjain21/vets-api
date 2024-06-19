# frozen_string_literal: true

module Vye
  class Vye::BdnClone < ApplicationRecord
    has_many :user_infos, dependent: :destroy

    validates :is_active, uniqueness: true

    def self.injested
      find_by(is_active: false)
    end

    def self.injested?
      injested.present?
    end

    # the newly injested BdnClone has `is_active` set to false
    # this method activates that BdnClone and sets it's UserInfo records to active
    # all other BdnClone, UserInfo get their active attribute set to nil
    def self.activate_injested!
      UserInfo.transaction do
        # rubocop:disable Rails/SkipsModelValidations
        UserInfo.where(bdn_clone_id: injested.id).update_all(bdn_clone_active: true)
        UserInfo.where.not(bdn_clone_id: injested.id).update_all(bdn_clone_active: nil)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end
  end
end
