# frozen_string_literal: true

require 'rails_helper'
require 'lighthouse/benefits_documents/worker_service'

RSpec.describe BenefitsDocuments::Form526::SubmitLighthouseDocumentService do

  describe '#call' do
    it 'submits the document to Lighthouse' do

    end

    # Log this properly
    it 'logs a successfull submission in DataDog'

    context 'when LighthouseDocument metadata is invalid' do
      it 'logs the error'

    end

    context 'when an invalid payload is sent to Lighthouse' do

    end
  end

  # Log when 
  context 'when invalid data'
end






