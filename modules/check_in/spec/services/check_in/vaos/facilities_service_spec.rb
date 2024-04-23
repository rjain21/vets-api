# frozen_string_literal: true

require 'rails_helper'

describe CheckIn::VAOS::FacilitiesService do
  subject { described_class.new }

  let(:service) { instance_double(VAOS::V2::MobileFacilityService) }

  before do
    allow(VAOS::V2::MobileFacilityService).to receive(:new).and_return(service)
  end

  describe '#initialize' do
    it 'returns an instance of service' do
      service_obj = subject
      expect(service_obj).to be_an_instance_of(CheckIn::VAOS::FacilitiesService)
    end
  end

  describe '#get_facilities' do
    let(:params) { { ids: ['123'], schedulable: true } }

    it 'calls get_facilities on the service with the correct parameters' do
      expect(service).to receive(:get_facilities).with(params)
      subject.get_facilities(**params)
    end
  end

  describe '#get_facilities_with_cache' do
    let(:ids) { ['123'] }

    it 'calls get_facilities_with_cache on the service with the correct parameters' do
      expect(service).to receive(:get_facilities_with_cache).with(ids)
      subject.get_facilities_with_cache(*ids)
    end
  end

  describe '#get_facility' do
    let(:facility_id) { '123' }

    it 'calls get_facility on the service with the correct parameters' do
      expect(service).to receive(:get_facility).with(facility_id)
      subject.get_facility(facility_id)
    end
  end

  describe '#get_facility_with_cache' do
    let(:facility_id) { '123' }

    it 'calls get_facility_with_cache on the service with the correct parameters' do
      expect(service).to receive(:get_facility_with_cache).with(facility_id)
      subject.get_facility_with_cache(facility_id)
    end
  end
end