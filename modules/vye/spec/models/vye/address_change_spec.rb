# frozen_string_literal: true

require 'rails_helper'
require Vye::Engine.root / 'spec/rails_helper'

RSpec.describe Vye::AddressChange, type: :model do
  it 'is valid with valid attributes' do
    address_change = build_stubbed(:vye_address_change)
    expect(address_change).to be_valid
  end

  describe '.todays_records' do
    it 'returns an array of hashes with the correct keys' do
      address_change = build_stubbed(:vye_address_change, created_at: Time.zone.now)
      user_info = address_change.user_info
      allow(Vye::AddressChange).to receive(:created_today).and_return([address_change])
      allow(user_info).to receive(:ssn).and_return('123456789')
      result = Vye::AddressChange.todays_records.first

      expect(result).to include(
        rpo: user_info.rpo_code,
        benefit_type: user_info.indicator,
        ssn: user_info.ssn,
        file_number: user_info.file_number,
        veteran_name: address_change.veteran_name,
        address1: address_change.address1,
        address2: address_change.address2,
        address3: address_change.address3,
        address4: address_change.address4,
        city: address_change.city,
        state: address_change.state,
        zip_code: address_change.zip_code
      )
    end
  end

  describe 'creates a report' do
    let!(:address_changes) { FactoryBot.create(:vye_address_change, user_info:) }

    before do
      ssn = '123456789'
      profile = double(ssn:)
      find_profile_by_identifier = double(profile:)
      service = double(find_profile_by_identifier:)
      allow(MPI::Service).to receive(:new).and_return(service)
    end

    it 'shows todays verifications' do
      expect(described_class.todays_records.length).to eq(1)
    end

    it 'shows todays verification report' do
      io = StringIO.new

      expect do
        described_class.todays_report(io)
      end.not_to raise_error

      io.rewind
      expect(io.read).to include('123456789')
    end
  end
end
