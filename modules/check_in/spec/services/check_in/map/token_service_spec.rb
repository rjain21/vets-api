# frozen_string_literal: true

require 'rails_helper'

describe CheckIn::Map::TokenService do
  subject { described_class.build(opts) }

  let(:check_in_uuid) { 'some_uuid' }
  let(:opts) { { check_in_uuid: }}
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)

    Rails.cache.clear
  end

  describe '.build' do
    it 'returns an instance of Service' do
      expect(subject).to be_an_instance_of(described_class)
    end
  end

  describe '#initialize' do
    it 'has a redis client' do
      expect(subject.redis_client).to be_a(CheckIn::Map::RedisClient)
    end

    it 'has a lorota redis client' do
      expect(subject.lorota_redis_client).to be_a(V2::Lorota::RedisClient)
    end
  end

  describe '#token' do
    let(:access_token) { 'test-token-123' }
    let(:expiration) { Time.zone.now + 20 }

    context 'when it exists in redis' do
      before do
        allow_any_instance_of(CheckIn::Map::RedisClient).to receive(:token).and_return(access_token)
      end

      it 'returns token from redis' do
        expect(subject.token).to eq(access_token)
      end
    end

    context 'when it does not exist in redis' do
      before do
        expect_any_instance_of(MAP::SecurityToken::Service).to receive(:token)
          .and_return({ access_token:, expiration: })
      end

      it 'returns token by calling client, and saves in redis' do
        redis_client = subject.redis_client
        expect(redis_client).to receive(:save_token)

        expect(subject.token).to eq(access_token)
      end
    end
  end

  describe '#patient_icn' do
    let(:patient_icn) { '123' }

    before do
      allow_any_instance_of(V2::Lorota::RedisClient).to receive(:icn).and_return(patient_icn)
    end

    it 'returns icn from lorota redis client' do
      expect(subject.patient_icn).to eq(patient_icn)
    end
  end
end
