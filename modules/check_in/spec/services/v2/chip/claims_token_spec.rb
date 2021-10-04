# frozen_string_literal: true

require 'rails_helper'

describe V2::Chip::ClaimsToken do
  subject { described_class }

  describe '.build' do
    it 'returns an instance of ClaimsToken' do
      expect(subject.build).to be_an_instance_of(V2::Chip::ClaimsToken)
    end
  end

  describe '#static' do
    it 'is an encoded base64 string' do
      base64_str = 'dmV0c2FwaVRlbXBVc2VyOlR6WTZERnJualBFOGR3eFVNYkZmOUhqYkZxUmltMk1nWHBNcE1' \
                   'jaVhKRlZvaHlVUlVKQWM3Vzk5cnBGemhmaDJCM3NWbm40'

      expect(subject.build.static).to eq(base64_str)
    end
  end

  describe '#tmp_api_id' do
    it 'has an api id' do
      expect(subject.build.tmp_api_id).to eq('2dcdrrn5zc')
    end
  end
end
