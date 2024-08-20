FactoryBot.define do
  factory :contact_information, class: 'VAProfile::Models::ContactInformation' do
    transient do
      custom_emails { [] }
      custom_telephones { [] }
      custom_addresses { [] }
      vet360_id { '12345' }
    end

    emails { custom_emails.any? ? custom_emails : [build(:email, vet360_id: vet360_id)] }
    telephones { custom_telephones.any? ? custom_telephones : [build(:telephone, vet360_id: vet360_id)] }
    addresses { custom_addresses.any? ? custom_addresses : [build(:va_profile_address, vet360_id: vet360_id)] }

    trait :with_mailing_address do
      addresses { [build(:va_profile_address, :mailing, vet360_id: vet360_id)] }
    end

    trait :with_international_address do
      addresses { [build(:va_profile_address, :international, vet360_id: vet360_id)] }
    end

    trait :with_military_overseas_address do
      addresses { [build(:va_profile_address, :military_overseas, vet360_id: vet360_id)] }
    end

    trait :with_multiple_matches_address do
      addresses { [build(:va_profile_address, :multiple_matches, vet360_id: vet360_id)] }
    end

    trait :with_override_address do
      addresses { [build(:va_profile_address, :override, vet360_id: vet360_id)] }
    end
  end
end
