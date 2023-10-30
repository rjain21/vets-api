# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BGS::SubmitForm686cJob, type: :job do
  let(:job) { subject.perform(user.uuid, user.icn, dependency_claim.id, vet_info) }
  let(:user) { FactoryBot.create(:evss_user, :loa3) }
  let(:dependency_claim) { create(:dependency_claim) }
  let(:all_flows_payload) { FactoryBot.build(:form_686c_674_kitchen_sink) }
  let(:birth_date) { '1809-02-12' }
  let(:client_stub) { instance_double(BGS::Form686c) }
  let(:vet_info) do
    {
      'veteran_information' => {
        'full_name' => {
          'first' => 'WESLEY', 'middle' => nil, 'last' => 'FORD'
        },
        'common_name' => user.common_name,
        'participant_id' => '600061742',
        'uuid' => user.uuid,
        'email' => user.email,
        'va_profile_email' => user.va_profile_email,
        'ssn' => '796043735',
        'va_file_number' => '796043735',
        'icn' => user.icn,
        'birth_date' => birth_date
      }
    }
  end
  let(:user_struct) do
    nested_info = vet_info['veteran_information']
    OpenStruct.new(
      first_name: nested_info['full_name']['first'],
      last_name: nested_info['full_name']['last'],
      middle_name: nested_info['full_name']['middle'],
      ssn: nested_info['ssn'],
      email: nested_info['email'],
      va_profile_email: nested_info['va_profile_email'],
      participant_id: nested_info['participant_id'],
      icn: nested_info['icn'],
      uuid: nested_info['uuid'],
      common_name: nested_info['common_name']
    )
  end

  before do
    allow_any_instance_of(SavedClaim::DependencyClaim).to receive(:submittable_674?).and_return(false)
    allow(OpenStruct).to receive(:new)
      .with(hash_including(icn: vet_info['veteran_information']['icn']))
      .and_return(user_struct)
  end

  it 'calls #submit for 686c submission' do
    expect(BGS::Form686c).to receive(:new).with(user_struct, dependency_claim).and_return(client_stub)
    expect(client_stub).to receive(:submit).once

    job
  end

  it 'sends confirmation email' do
    expect(BGS::Form686c).to receive(:new).with(user_struct, dependency_claim).and_return(client_stub)
    expect(client_stub).to receive(:submit).once

    expect(VANotify::EmailJob).to receive(:perform_async).with(
      user.va_profile_email,
      'fake_template_id',
      {
        'date' => Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%B %d, %Y'),
        'first_name' => 'WESLEY'
      }
    )

    job
  end

  context 'Claim is submittable_674' do
    it 'enqueues SubmitForm674Job' do
      allow_any_instance_of(SavedClaim::DependencyClaim).to receive(:submittable_674?).and_return(true)
      expect(BGS::Form686c).to receive(:new).with(user_struct, dependency_claim).and_return(client_stub)
      expect(client_stub).to receive(:submit).once
      expect(BGS::SubmitForm674Job).to receive(:perform_async).with(user.uuid, user.icn,
                                                                    dependency_claim.id, vet_info, user_struct.to_h)

      job
    end
  end

  context 'Claim is not submittable_674' do
    it 'does not enqueue SubmitForm674Job' do
      expect(BGS::Form686c).to receive(:new).with(user_struct, dependency_claim).and_return(client_stub)
      expect(client_stub).to receive(:submit).once
      expect(BGS::SubmitForm674Job).not_to receive(:perform_async)

      job
    end
  end

  context 'when submission raises error' do
    before do
      Flipper.enable(:dependents_central_submission)
    end

    it 'raises error' do
      expect(BGS::Form686c).to receive(:new).with(user_struct, dependency_claim).and_return(client_stub)
      expect(client_stub).to receive(:submit).and_raise(BGS::SubmitForm686cJob::Invalid686cClaim)

      expect do
        subject.perform(user.uuid, user.icn, dependency_claim.id,
                        vet_info)
      end.to raise_error(BGS::SubmitForm686cJob::Invalid686cClaim)
    end
  end
end
