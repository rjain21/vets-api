# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AskVAApi::V0::StaticDataController, type: :request do
  let(:datadog_logger) { instance_double(DatadogLogger) }
  let(:span) { instance_double(Datadog::Tracing::Span) }

  before do
    allow(DatadogLogger).to receive(:new).and_return(datadog_logger)
    allow(datadog_logger).to receive(:call).and_yield(span)
    allow(span).to receive(:set_tag)
    allow(Rails.logger).to receive(:error)
  end

  describe 'GET #index' do
    let(:index_path) { '/ask_va_api/v0/static_data' }
    let(:expected_response) do
      {
        'Emily' => {
          'data-info' => 'emily@oddball.io'
        }, 'Eddie' => {
          'data-info' => 'eddie.otero@oddball.io'
        }, 'Jacob' => {
          'data-info' => 'jacob@docme360.com'
        }, 'Joe' => {
          'data-info' => 'joe.hall@thoughtworks.com'
        }, 'Khoa' => {
          'data-info' => 'khoa.nguyen@oddball.io'
        }
      }
    end

    before do
      get index_path
    end

    context 'when successful' do
      it 'returns status of 200 and the correct response data' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(expected_response)
      end
    end
  end

  describe 'GET #categories' do
    let(:categories_path) { '/ask_va_api/v0/categories' }
    let(:expected_hash) do
      { 'id' => '2', 'type' => 'categories', 'attributes' => { 'name' => 'Benefits Issues Outside the US' } }
    end

    context 'when successful' do
      before do
        get categories_path
      end

      it 'returns categories data' do
        expect(JSON.parse(response.body)['data']).to include(a_hash_including(expected_hash))
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when an error occurs' do
      before do
        allow_any_instance_of(Dynamics::Service)
          .to receive(:call)
          .and_raise(Dynamics::ErrorHandler::BadRequestError.new('bad request'))
        get categories_path
      end

      it 'handles other exceptions and returns an internal server error response' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Dynamics::ErrorHandler::BadRequestError: bad request' })
      end

      it 'logs and renders error and sets datadog tags' do
        expect(response).to have_http_status(status)
        expect(JSON.parse(response.body)['error']).to eq('Dynamics::ErrorHandler::BadRequestError: bad request')
        expect(datadog_logger).to have_received(:call).with('service_error')
        expect(span).to have_received(:set_tag).with('error', true)
        expect(span).to have_received(:set_tag).with('error.msg',
                                                     'Dynamics::ErrorHandler::BadRequestError: bad request')
        expect(Rails.logger).to have_received(:error)
          .with('Error during service_error: Dynamics::ErrorHandler::BadRequestError: bad request')
      end
    end
  end

  describe 'GET #Topics' do
    let(:category) do
      AskVAApi::Categories::Entity.new({ id: 2, category: 'VA Health' })
    end
    let(:expected_response) do
      { 'data' =>
        [{ 'id' => '6', 'type' => 'topics', 'attributes' => { 'name' => 'Compensation' } },
         { 'id' => '7', 'type' => 'topics',
           'attributes' => { 'name' => 'Education (Ch.30, 33, 35, 1606, etc. & Work Study)' } },
         { 'id' => '8', 'type' => 'topics', 'attributes' => { 'name' => 'GI Bill' } },
         { 'id' => '9', 'type' => 'topics',
           'attributes' => { 'name' => 'Health Eligibility/Enrollment (Veterans)' } }] }
    end
    let(:topics_path) { "/ask_va_api/v0/categories/#{category.id}/topics" }

    context 'when successful' do
      before { get topics_path }

      it 'returns topics data' do
        expect(JSON.parse(response.body)).to eq(expected_response)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when an error occurs' do
      before do
        allow_any_instance_of(Dynamics::Service)
          .to receive(:call)
          .and_raise(Dynamics::ErrorHandler::BadRequestError.new('bad request'))
        get topics_path
      end

      it 'handles other exceptions and returns an internal server error response' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Dynamics::ErrorHandler::BadRequestError: bad request' })
      end

      it 'logs and renders error and sets datadog tags' do
        expect(response).to have_http_status(status)
        expect(JSON.parse(response.body)['error']).to eq('Dynamics::ErrorHandler::BadRequestError: bad request')
        expect(datadog_logger).to have_received(:call).with('service_error')
        expect(span).to have_received(:set_tag).with('error', true)
        expect(span).to have_received(:set_tag).with('error.msg',
                                                     'Dynamics::ErrorHandler::BadRequestError: bad request')
        expect(Rails.logger).to have_received(:error)
          .with('Error during service_error: Dynamics::ErrorHandler::BadRequestError: bad request')
      end
    end
  end
end
