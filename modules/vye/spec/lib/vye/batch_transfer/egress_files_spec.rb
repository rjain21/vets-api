# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Vye::BatchTransfer::EgressFiles do
  describe '#address_changes_filename' do
    it 'returns a string' do
      expect(described_class.send(:address_changes_filename)).to be_a(String)
    end
  end

  describe '#direct_deposit_filename' do
    it 'returns a string' do
      expect(described_class.send(:direct_deposit_filename)).to be_a(String)
    end
  end

  describe '#verification_filename' do
    it 'returns a string' do
      expect(described_class.send(:verification_filename)).to be_a(String)
    end
  end
end
