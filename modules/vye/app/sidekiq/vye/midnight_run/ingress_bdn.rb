# frozen_string_literal: true

module Vye
  class MidnightRun
    class IngressBdn
      include Sidekiq::Worker

      def perform; end
    end
  end
end
