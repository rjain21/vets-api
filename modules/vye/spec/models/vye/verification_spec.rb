# frozen_string_literal: true

require 'rails_helper'
require Vye::Engine.root / 'spec/rails_helper'

RSpec.describe Vye::Verification, type: :model do
  it 'is valid with valid attributes' do
    address_change = build_stubbed(:vye_verification)
    expect(address_change).to be_valid
  end

  describe 'creates a report' do
    before do
      old_bdn = FactoryBot.create(:vye_bdn_clone, is_active: true, export_ready: nil)
      new_bdn = FactoryBot.create(:vye_bdn_clone, is_active: false, export_ready: nil)

      7.times { FactoryBot.create(:vye_user_info, :with_verifications, bdn_clone: old_bdn) }
      new_bdn.activate!

      ssn = '123456789'
      profile = double(ssn:)
      find_profile_by_identifier = double(profile:)
      service = double(find_profile_by_identifier:)
      allow(MPI::Service).to receive(:new).and_return(service)
    end

    it 'produces report rows' do
      expect(described_class.report_rows.length).to eq(7)
    end

    it 'writes out a report' do
      io = StringIO.new

      expect do
        described_class.write_report(io)
      end.not_to raise_error

      io.rewind
      
      expect(io.string.scan('123456789').count).to be(7)
    end
  end

  # describe 'show todays verifications' do
  #   let!(:user_profile) { FactoryBot.create(:vye_user_profile) }
  #   let!(:user_info) { FactoryBot.create(:vye_user_info, user_profile:) }
  #   let!(:award) { FactoryBot.create(:vye_award, user_info:) }
  #   let!(:verification) { FactoryBot.create(:vye_verification, award:, user_profile:) }

  #   before do
  #     ssn = '123456789'
  #     profile = double(ssn:)
  #     find_profile_by_identifier = double(profile:)
  #     service = double(find_profile_by_identifier:)
  #     allow(MPI::Service).to receive(:new).and_return(service)
  #   end

  #   it 'shows todays verifications' do
  #     expect(Vye::Verification.todays_verifications.length).to eq(1)
  #   end

  #   it 'shows todays verification report' do
  #     expect(Vye::Verification.todays_verifications_report).to be_a(String)
  #   end
  # end
end
