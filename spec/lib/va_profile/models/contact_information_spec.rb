# frozen_string_literal: true

require 'rails_helper'
require 'va_profile/models/contact_information'

describe VAProfile::Models::ContactInformation do
  let(:contact_info) do
    build(:contact_information, :with_mailing_address).tap do |ci|
      ci.telephones = [build(:telephone, phone_number: '5551234', phone_type: 'MOBILE')]
      ci.emails = [build(:email, email_address: 'example@example.com')]
    end
  end

  describe 'validation', :aggregate_failures do
    context 'for email validation' do
      it 'validates presence of email address' do
        contact_info.emails.first.email_address = ''
        expect(contact_info.valid?).to eq(false)
      end

      it 'validates format of email address' do
        contact_info.emails.first.email_address = 'invalid-email'
        expect(contact_info.valid?).to eq(false)
      end
    end

    context 'for phone number validation' do
      it 'is valid with a valid phone number' do
        phone = build(:telephone, phone_number: '3035551234')
        expect(phone).to be_valid
      end

      it 'is not valid with an invalid phone number' do
        phone = build(:telephone, phone_number: 'invalid')
        expect(phone).not_to be_valid
        expect(phone.errors[:phone_number].first).to eq('is invalid')
      end
    end

    context 'for address validation' do
      it 'is valid with a valid address' do
        address = build(:va_profile_address, address_line1: '123 Main St', city: 'Anytown', state_code: 'VA', zip_code: '12345')
        contact_info.addresses = [address]
        expect(contact_info).to be_valid
      end

      # address validation is handled through a separate endpoint - ADAM

    end
  end

  describe 'serialization' do
    it 'serializes to JSON correctly' do
      json_data = JSON.parse(contact_info.in_json)
      expect(json_data['bio']['emails'].first['emailAddressText']).to eq(contact_info.emails.first.email_address)
      expect(json_data['bio']['telephones'].first['phoneNumber']).to eq(contact_info.telephones.first.phone_number)
      expect(json_data['bio']['addresses'].first['addressLine1']).to eq(contact_info.addresses.first.address_line1)
      expect(json_data['bio']['addresses'].first['cityName']).to eq(contact_info.addresses.first.city)
      expect(json_data['bio']['addresses'].first['stateCode']).to eq(contact_info.addresses.first.state_code)
      expect(json_data['bio']['addresses'].first['zipCode5']).to eq(contact_info.addresses.first.zip_code)
      expect(json_data['bio']['permissions'].first['permissionValue'].to eq(contact_info.permissions.first.permission_value ))
    end
  end
end
