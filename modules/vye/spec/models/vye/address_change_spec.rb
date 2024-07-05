# frozen_string_literal: true

require 'rails_helper'
require Vye::Engine.root / 'spec/rails_helper'

RSpec.describe Vye::AddressChange, type: :model do
  it 'is valid with valid attributes' do
    address_change = build_stubbed(:vye_address_change)
    expect(address_change).to be_valid
  end

  describe 'creates a report' do
    before do
      FactoryBot.create(:vye_bdn_clone, is_active: nil, export_ready: nil)
      FactoryBot.create(:vye_bdn_clone, is_active: nil, export_ready: nil)
      FactoryBot.create(:vye_bdn_clone, is_active: false, export_ready: true)
      bdn_clone = FactoryBot.create(:vye_bdn_clone, is_active: true, export_ready: false)

      7.times { FactoryBot.create(:vye_user_info, :with_address_changes, bdn_clone:) }
      bdn_clone.activate!

      ssn = '123456789'
      profile = double(ssn:)
      find_profile_by_identifier = double(profile:)
      service = double(find_profile_by_identifier:)
      allow(MPI::Service).to receive(:new).and_return(service)
    end

    it 'shows todays verifications' do
      expect(described_class.report_rows.length).to eq(7)
    end

    it 'shows todays verification report' do
      io = StringIO.new

      expect do
        described_class.write_report(io)
      end.not_to raise_error

      io.rewind
      
      expect(io.string.scan('123456789').count).to be(7)
    end
  end
end
