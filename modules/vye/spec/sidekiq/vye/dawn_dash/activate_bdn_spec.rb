# frozen_string_literal: true

require 'rails_helper'
require Vye::Engine.root / 'spec/rails_helper'

describe Vye::DawnDash::ActivateBdn, type: :worker do
  before do
    allow(Vye::BdnClone).to receive(:injested?).and_return(true)
    allow(Vye::BdnClone).to receive(:activate!)
  end

  it 'enqueues child jobs' do
    expect do
      described_class.new.perform
    end.to change { Sidekiq::Worker.jobs.size }.by(1)

    expect(Vye::DawnDash::EgressUpdates).to have_enqueued_sidekiq_job
  end
end
