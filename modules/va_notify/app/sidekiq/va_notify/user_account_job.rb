# frozen_string_literal: true

module VANotify
  class UserAccountJob
    include Sidekiq::Job
    include SentryLogging
    sidekiq_options retry: 14

    sidekiq_retries_exhausted do |msg, _ex|
      job_id = msg['jid']
      job_class = msg['class']
      error_class = msg['error_class']
      error_message = msg['error_message']

      message = "#{job_class} retries exhausted"
      Rails.logger.error(message, { job_id:, error_class:, error_message: })
      StatsD.increment("sidekiq.jobs.#{job_class.underscore}.retries_exhausted")
    end

    # rubocop:disable Metrics/MethodLength
    def perform(
      user_account_id,
      template_id,
      personalisation = nil,
      api_key = Settings.vanotify.services.va_gov.api_key
    )
      user_account = UserAccount.find(user_account_id)
      notify_client = VaNotify::Service.new(api_key)

      notify_client.send_email(
        {
          recipient_identifier: { id_value: user_account.icn, id_type: 'ICN' },
          template_id:, personalisation:
        }.compact
      )
    rescue Common::Exceptions::BackendServiceException => e
      if e.status_code == 400
        log_exception_to_sentry(
          e,
          {
            args: { recipient_identifier: { id_value: user_account.id, id_type: 'UserAccountId' },
                    template_id:, personalisation: }
          },
          { error: :va_notify_icn_job }
        )
      else
        raise e
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
