# frozen_string_literal: true

require 'va_notify/service'

module EVSS
  module DisabilityCompensationForm
    class Form0781DocumentUploadFailureEmail < Job
      STATSD_METRIC_PREFIX = 'api.form_526.veteran_notifications.form0781_document_upload_failure_email'

      # retry for one day
      sidekiq_options retry: 14

      sidekiq_retries_exhausted do |msg, _ex|
        job_id = msg['jid']
        error_class = msg['error_class']
        timestamp = Time.now.utc
        form526_submission_id = msg['args'].first

        # Job status records are upserted in the JobTracker module
        # when the retryable_error_handler is called
        form_job_status = Form526JobStatus.find_by(job_id:)
        bgjob_errors = form_job_status.bgjob_errors || {}
        new_error = {
          "#{timestamp.to_i}": {
            caller_method: __method__.to_s,
            timestamp:,
            form526_submission_id:,
          }
        }
        form_job_status.update(
          status: Form526JobStatus::STATUS[:exhausted],
          bgjob_errors: bgjob_errors.merge(new_error)
        )

        Rails.logger.warn(
          'Form0781DocumentUploadFailureEmail retries exhausted',
          { job_id:, timestamp:, form526_submission_id:, error_class: }
        )

        StatsD.increment("#{STATSD_METRIC_PREFIX}.exhausted")
      rescue => e
        Rails.logger.error(
          'Failure in Form526DocumentUploadFailureEmail#sidekiq_retries_exhausted',
          {
            job_id:,
            submission_id: form526_submission_id,
            pre_exhaustion_failure: {
              error_class:
            }
          }
        )
        raise e
      end

      def perform(form526_submission_id)
        form526_submission = Form526Submission.find(form526_submission_id)

        with_tracking('Form0781DocumentUploadFailureEmail', form526_submission.saved_claim_id, form526_submission_id) do
          @notify_client ||= VaNotify::Service.new(Settings.vanotify.services.benefits_disability.api_key)

          email_address = form526_submission.veteran_email_address
          first_name = form526_submission.get_first_name
          date_submitted = form526_submission.format_creation_time_for_mailers

          @notify_client.send_email(
            email_address:,
            template_id: mailer_template_id,
            personalisation: {
              first_name:,
              date_submitted:
            }
          )

          StatsD.increment("#{STATSD_METRIC_PREFIX}.success")
        end
      end

      private

      def mailer_template_id
        Settings.vanotify.services
                .benefits_disability.template_id.form0781_failure_notification_template_id
      end
    end
  end
end
