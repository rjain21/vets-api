# frozen_string_literal: true

module Vye
  class DawnDash
    class EgressUpdates
      include Sidekiq::Worker

      def perform; end
    end
  end
end
