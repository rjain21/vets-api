# frozen_string_literal: true

require 'central_mail/service'
require 'central_mail/datestamp_pdf'
require 'pension_burial/tag_sentry'
require 'benefits_intake_service/service'
require 'simple_forms_api_submission/metadata_validator'
require 'pdf_info'

module Lighthouse
  class SubmitBenefitsIntakeClaim
    include Sidekiq::Job
    include SentryLogging
    class BenefitsIntakeClaimError < StandardError; end

    FOREIGN_POSTALCODE = '00000'
    STATSD_KEY_PREFIX = 'worker.central_mail.submit_benefits_intake_claim'

    # Sidekiq has built in exponential back-off functionality for retries
    # A max retry attempt of 14 will result in a run time of ~25 hours
    RETRY = 14

    sidekiq_options retry: RETRY

    sidekiq_retries_exhausted do |msg, _ex|
      Rails.logger.send(
        :error,
        "Failed all retries on CentralMail::SubmitBenefitsIntakeClaim, last error: #{msg['error_message']}"
      )
      StatsD.increment("#{STATSD_KEY_PREFIX}.exhausted")
    end

    # rubocop:disable Metrics/MethodLength
    def perform(saved_claim_id)
      @claim = SavedClaim.find(saved_claim_id)
      @pdf_path = process_record(@claim)
      @attachment_paths = @claim.persistent_attachments.map do |record|
        process_record(record)
      end

      @lighthouse_service = BenefitsIntakeService::Service.new(with_upload_location: true)
      create_form_submission_attempt(@lighthouse_service.uuid)

      payload = {
        upload_url: @lighthouse_service.location,
        file: split_file_and_path(@pdf_path),
        metadata: generate_metadata.to_json,
        attachments: @attachment_paths.map(&method(:split_file_and_path))
      }

      response = @lighthouse_service.upload_doc(**payload)

      if response.success?
        log_message_to_sentry('CentralMail::SubmitSavedClaimJob succeeded', :info, generate_sentry_details)
        @claim.send_confirmation_email if @claim.respond_to?(:send_confirmation_email)
      else
        raise BenefitsIntakeClaimError, response.body
      end
    rescue => e
      log_message_to_sentry('CentralMail::SubmitBenefitsIntakeClaim failed, retrying...', :warn,
                            generate_sentry_details(e))
      raise
    ensure
      cleanup_file_paths
    end

    # rubocop:enable Metrics/MethodLength
    def generate_metadata
      form = @claim.parsed_form
      veteran_full_name = form['veteranFullName']
      address = form['claimantAddress'] || form['veteranAddress']

      metadata = {
        'veteranFirstName' => veteran_full_name['first'],
        'veteranLastName' => veteran_full_name['last'],
        'fileNumber' => form['vaFileNumber'] || form['veteranSocialSecurityNumber'],
        'zipCode' => address['country'] == 'USA' ? address['postalCode'] : FOREIGN_POSTALCODE,
        'source' => "#{@claim.class} va.gov",
        'docType' => @claim.form_id,
        'businessLine' => @claim.business_line
      }

      SimpleFormsApiSubmission::MetadataValidator.validate(metadata)
    end

    def process_record(record)
      pdf_path = record.to_pdf
      stamped_path = CentralMail::DatestampPdf.new(pdf_path).run(text: 'VA.GOV', x: 5, y: 5)
      CentralMail::DatestampPdf.new(stamped_path).run(
        text: 'FDC Reviewed - va.gov Submission',
        x: 429,
        y: 770,
        text_only: true
      )
    end

    def split_file_and_path(path)
      { file: path, file_name: path.split('/').last }
    end

    private

    def generate_sentry_details(e = nil)
      details = {
        'guid' => @claim&.guid,
        'docType' => @claim&.form_id,
        'savedClaimId' => @saved_claim_id
      }
      details['error'] = e.message if e
      details
    end

    def create_form_submission_attempt(intake_uuid)
      form_submission = FormSubmission.create(
        form_type: @claim.form_id,
        form_data: @claim.to_json,
        benefits_intake_uuid: intake_uuid,
        saved_claim: @claim
      )
      @form_submission_attempt = FormSubmissionAttempt.create(form_submission:)
    end

    def cleanup_file_paths
      Common::FileHelpers.delete_file_if_exists(@pdf_path) if @pdf_path
      @attachment_paths&.each { |p| Common::FileHelpers.delete_file_if_exists(p) }
    end
  end
end
