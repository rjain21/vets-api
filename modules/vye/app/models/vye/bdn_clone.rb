# frozen_string_literal: true

module Vye
  class Vye::BdnClone < ApplicationRecord
    has_many :user_infos, dependent: :destroy

    # BDN Clone Stages
    # |-------------------------------------------------|
    # | is_active | export_ready | description          |
    # |-----------|--------------|----------------------|
    # | false     |   nil        | fresh import         |
    # | true      |   nil        | currently active     |
    # | nil       |   true       | ready to be exported |
    # |-------------------------------------------------|

    validates :is_active, :export_ready, uniqueness: true, allow_nil: true

    public

    def activate!
      transaction do
        old = self.class.find_by(is_active: true)

        if old.present?
          old.update!(is_active: nil, export_ready: true)
          # rubocop:disable Rails/SkipsModelValidations
          UserInfo.where(bdn_clone_id: old.id).update_all(bdn_clone_active: nil)
          # rubocop:enable Rails/SkipsModelValidations
        end

        self.update!(is_active: true)
        # rubocop:disable Rails/SkipsModelValidations
        UserInfo.where(bdn_clone_id: id).update_all(bdn_clone_active: true)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end
  end
end
