FactoryBot.define do
  factory :contact_information, class: 'VAProfile::Models::ContactInformation' do
    transient do
      custom_emails { [] }
      custom_telephones { [] }
      custom_addresses { [] }
    end

    emails { custom_emails.any? ? custom_emails : [build(:email)] }
    telephones { custom_telephones.any? ? custom_telephones : [build(:telephone)] }
    addresses { custom_addresses.any? ? custom_addresses : [build(:va_profile_address)] }

    trait :with_mailing_address do
      addresses { [build(:va_profile_address, :mailing)] }
    end

    trait :with_international_address do
      addresses { [build(:va_profile_address, :international)] }
    end

    trait :with_military_overseas_address do
      addresses { [build(:va_profile_address, :military_overseas)] }
    end

    trait :with_multiple_matches_address do
      addresses { [build(:va_profile_address, :multiple_matches)] }
    end

    trait :with_override_address do
      addresses { [build(:va_profile_address, :override)] }
    end
  end
end
