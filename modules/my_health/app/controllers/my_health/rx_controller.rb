# frozen_string_literal: true

require 'rx/client'

module MyHealth
  class RxController < ApplicationController
    include ActionController::Serialization
    include MyHealth::MHVControllerConcerns

    skip_before_action :authenticate

    protected

    def client
      # @client ||= Rx::Client.new(session: { user_id: current_user.mhv_correlation_id })
      @client ||= Rx::Client.new(session: { user_id: 17621060 }) # staging elena12
      # @client ||= Rx::Client.new(session: { user_id: 16955936 }) # staging
      # @client ||= Rx::Client.new(session: { user_id: 22300170 }) # staging
      # @client ||= Rx::Client.new(session: { user_id: 1460597 }) # dev

    end

    def authorize
      # raise_access_denied unless current_user.authorize(:mhv_prescriptions, :access?)
    end

    def raise_access_denied
      raise Common::Exceptions::Forbidden, detail: 'You do not have access to prescriptions'
    end
  end
end