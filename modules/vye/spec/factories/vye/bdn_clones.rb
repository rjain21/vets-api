# frozen_string_literal: true

FactoryBot.define do
  factory :vye_bdn_clone, class: 'Vye::BdnClone' do
    is_active { true }
    export_ready { false }

    after(:create) do |bdn_clone|
      create_list(:vye_user_info, 3, bdn_clone:)
    end
  end
end
