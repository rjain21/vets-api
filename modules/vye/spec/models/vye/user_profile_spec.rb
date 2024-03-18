# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Vye::UserProfile, type: :model do
  describe 'find_by_user after ICN is recorded' do
    let!(:user) { create(:evss_user, :loa3) }
    let!(:user_profile) { described_class.create(ssn: user.ssn, file_number: user.ssn, icn: user.icn) }

    it 'finds the user info by icn' do
      u = described_class.find_and_update_icn(user:)
      expect(u).to eq(user_profile)
    end
  end

  describe 'find_by_user before ICN is recorded' do
    let!(:user) { create(:evss_user, :loa3) }
    let!(:user_profile) { described_class.create(ssn: user.ssn, file_number: user.ssn) }

    it 'finds the user info by ssn' do
      u = described_class.find_and_update_icn(user:)

      expect(u).to eq(user_profile)

      expect(u.ssn_digest_in_database.length).to be(16)
      expect(u.ssn_digest.length).to be(36)

      expect(u.icn_in_database).to eq(user.icn)
    end
  end
end
