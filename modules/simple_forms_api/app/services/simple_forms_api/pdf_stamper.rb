# frozen_string_literal: true

require 'pdf_utilities/datestamp_pdf'

module SimpleFormsApi
  class PdfStamper
    attr_reader :stamped_template_path, :form, :loa

    SUBMISSION_TEXT = 'Signed electronically and submitted via VA.gov at '
    SUBMISSION_DATE_TITLE = 'Application Submitted:'

    def initialize(stamped_template_path, form, loa = nil)
      @stamped_template_path = stamped_template_path
      @form = form
      @loa = loa
    end

    def stamp_pdf
      all_form_stamps.each do |desired_stamp|
        stamp_form(desired_stamp)
      end

      stamp_auth_text
    rescue => e
      raise StandardError, "An error occurred while stamping the PDF: #{e}"
    end

    def self.stamp4010007_uuid(uuid)
      desired_stamp = { text: "UUID: #{uuid}", font_size: 9 }
      stamped_template_path = 'tmp/vba_40_10007-tmp.pdf'
      desired_stamps = [[390, 18]]
      page_configuration = [
        { type: :text, position: desired_stamps[0] }
      ]

      verified_multistamp(stamped_template_path, desired_stamp, page_configuration)
    end

    private

    def all_form_stamps
      form.desired_stamps + form.submission_date_stamps
    end

    def stamp_form(desired_stamp)
      if desired_stamp[:page]
        stamp_specified_page(desired_stamp)
      else
        stamp_all_pages(desired_stamp)
      end
    end

    def stamp_specified_page(desired_stamp)
      page_configuration = get_page_configuration(desired_stamp)
      verified_multistamp(stamped_template_path, desired_stamp, page_configuration)
    end

    def stamp_all_pages(desired_stamp, append_to_stamp: nil)
      current_file_path = call_datestamp_pdf(stamped_template_path, desired_stamp, append_to_stamp)
      File.rename(current_file_path, stamped_template_path)
    end

    def stamp_auth_text
      desired_stamp = get_auth_text_stamp
      auth_text = case loa
                  when 3
                    'Signee signed with an identity-verified account.'
                  when 2
                    'Signee signed in but hasn’t verified their identity.'
                  else
                    'Signee not signed in.'
                  end
      verify(stamped_template_path) do
        stamp_all_pages(desired_stamp, append_to_stamp: auth_text)
      end
    end

    def verified_multistamp(stamped_template_path, stamp, page_configuration)
      raise StandardError, 'The provided stamp content was empty.' if stamp[:text].blank?

      verify(stamped_template_path) { multistamp(stamped_template_path, stamp, page_configuration) }
    end

    def multistamp(stamped_template_path, stamp, page_configuration)
      generate_prawn_document(stamp, page_configuration)

      perform_multistamp(stamped_template_path, stamp_path)
    rescue => e
      Rails.logger.error 'Simple forms api - Failed to generate stamped file', message: e.message
      raise
    ensure
      Common::FileHelpers.delete_file_if_exists(stamp_path) if defined?(stamp_path)
    end

    def perform_multistamp(stamped_template_path, stamp_path)
      out_path = Rails.root.join("#{Common::FileHelpers.random_file_path}.pdf")
      pdftk = PdfFill::Filler::PDF_FORMS
      pdftk.multistamp(stamped_template_path, stamp_path, out_path)
      Common::FileHelpers.delete_file_if_exists(stamped_template_path)
      File.rename(out_path, stamped_template_path)
    rescue => e
      Rails.logger.error 'Simple forms api - Failed to perform multistamp', message: e.message
      Common::FileHelpers.delete_file_if_exists(out_path)
      raise e
    end

    def verify(template_path)
      orig_size = File.size(template_path)
      yield
      stamped_size = File.size(template_path)

      raise StandardError, 'The PDF remained unchanged upon stamping.' unless stamped_size > orig_size
    rescue Prawn::Errors::IncompatibleStringEncoding
      raise
    rescue => e
      raise StandardError, "An error occurred while verifying stamp: #{e}"
    end

    def get_page_configuration(stamp)
      page = stamp[:page]
      position = stamp[:coords]
      [
        { type: :new_page },
        { type: :new_page },
        { type: :new_page },
        { type: :new_page },
        { type: :new_page }
      ].tap do |config|
        config[page] = { type: :text, position: }
      end
    end

    def generate_prawn_document(stamp, page_configuration)
      stamp_path = Rails.root.join(Common::FileHelpers.random_file_path)
      Prawn::Document.generate(stamp_path, margin: [0, 0]) do |pdf|
        page_configuration.each do |config|
          case config[:type]
          when :text
            pdf.draw_text stamp[:text], at: config[:position], size: stamp[:font_size] || 16
          when :new_page
            pdf.start_new_page
          end
        end
      end
    end

    def call_datestamp_pdf(stamped_template_path, desired_stamp, append_to_stamp)
      Rails.logger.info('Calling PDFUtilities::DatestampPdf', current_file_path:, stamped_template_path:)
      datestamp_instance = PDFUtilities::DatestampPdf.new(stamped_template_path, append_to_stamp:)
      coords = desired_stamp[:coords]
      datestamp_instance.run(text: desired_stamp[:text], x: coords[0], y: coords[1], text_only: true, size: 9)
    end

    def get_auth_text_stamp
      current_time = "#{Time.current.in_time_zone('America/Chicago').strftime('%H:%M:%S')} "
      coords = [10, 10]
      text = SUBMISSION_TEXT + current_time
      { coords:, text: }
    end
  end
end
