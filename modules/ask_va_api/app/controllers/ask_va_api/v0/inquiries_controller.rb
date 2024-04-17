# frozen_string_literal: true

module AskVAApi
  module V0
    class InquiriesController < ApplicationController
      around_action :handle_exceptions
      before_action :get_inquiries_by_icn, only: [:index]
      before_action :get_inquiry_by_id, only: [:show]
      skip_before_action :authenticate, only: %i[unauth_create upload_attachment test_create]
      skip_before_action :verify_authenticity_token, only: %i[unauth_create upload_attachment test_create]

      def index
        render json: @user_inquiries.payload, status: @user_inquiries.status
      end

      def show
        render json: @inquiry.payload, status: @inquiry.status
      end

      def test_create
        service = Crm::Service.new(icn: nil)
        payload = { reply: params[:reply] }
        response = service.call(endpoint: params[:endpoint], method: :post, payload:)

        render json: response.to_json, status: :ok
      end

      def create
        render json: { message: 'success' }, status: :created
      end

      def unauth_create
        response = Inquiries::Creator.new(icn: nil).call(params: inquiry_params)
        render json: { message: response }, status: :created
      end

      def upload_attachment
        uploader = AttachmentUploader.new(params[:attachment])
        result = uploader.call
        render json: { message: result[:message] || result[:error] }, status: result[:status]
      end

      def download_attachment
        render json: get_attachment.payload, status: get_attachment.status
      end

      def profile
        render json: get_profile.payload, status: get_profile.status
      end

      def status
        stat = Inquiries::Status::Retriever.new(icn: current_user.icn).call(inquiry_number: params[:id])
        serializer = Inquiries::Status::Serializer.new(stat)
        render json: serializer.serializable_hash, status: :ok
      end

      def create_reply
        response = Correspondences::Creator.new(message: params[:reply], inquiry_id: params[:id], service: nil).call
        render json: response.to_json, status: :ok
      end

      private

      def inquiry_params
        params.permit(:first_name, :last_name).to_h
      end

      def get_inquiry_by_id
        inq = retriever.fetch_by_id(id: params[:id])
        @inquiry = Result.new(payload: Inquiries::Serializer.new(inq).serializable_hash, status: :ok)
      end

      def get_inquiries_by_icn
        inquiries = retriever.call
        @user_inquiries = Result.new(payload: Inquiries::Serializer.new(inquiries).serializable_hash, status: :ok)
      end

      def get_attachment
        att = Attachments::Retriever.new(id: params[:id], service: mock_service).call

        raise InvalidAttachmentError if att.blank?

        Result.new(payload: Attachments::Serializer.new(att).serializable_hash, status: :ok)
      end

      def get_profile
        profile = Profile::Retriever.new(icn: current_user.icn, user_mock_data: params[:user_mock_data]).call

        Result.new(payload: Profile::Serializer.new(profile).serializable_hash, status: :ok)
      end

      def mock_service
        DynamicsMockService.new(icn: nil, logger: nil) if params[:mock]
      end

      def retriever
        entity_class = AskVAApi::Inquiries::Entity
        @retriever ||= Inquiries::Retriever.new(icn: current_user.icn, user_mock_data: params[:mock], entity_class:)
      end

      Result = Struct.new(:payload, :status, keyword_init: true)
      class InvalidAttachmentError < StandardError; end
    end
  end
end
