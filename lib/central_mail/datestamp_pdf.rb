# frozen_string_literal: true

require 'common/file_helpers'
require 'pdf_fill/filler'

module CentralMail
  class DatestampPdf
    def initialize(file_path, append_to_stamp: nil)
      @file_path = file_path
      @append_to_stamp = append_to_stamp
    end

    def run(settings)
      stamp_path = Common::FileHelpers.random_file_path
      generate_stamp(stamp_path, settings[:text], settings[:x], settings[:y], settings[:text_only], settings[:size], settings[:page_number, settings[:template]])
      stamp(@file_path, stamp_path, multistamp: settings[:multistamp])
    ensure
      Common::FileHelpers.delete_file_if_exists(stamp_path) if defined?(stamp_path)
    end

    # rubocop:disable Metrics/ParameterLists
    def def generate_stamp(stamp_path, text, x, y, text_only, size = 10, timestamp = nil, page_number = nil, template = nil)
      unless text_only
        text += " #{I18n.l(Time.zone.now, format: :pdf_stamp)}"
        text += ". #{@append_to_stamp}" if @append_to_stamp
      end

      Prawn::Document.generate(stamp_path, margin: [0, 0]) do |pdf|
        if page_number.present? && template.present?
          reader = PDF::Reader.new(template)
          page_number.times do
            pdf.start_new_page
          end
          (pdf.draw_text text, at: [x, y], size:)
          (pdf.draw_text timestamp.strftime('%Y-%m-%d %I:%M %p %Z'), at: [x, y - 12], size:)
          (reader.page_count - page_number).times do
            pdf.start_new_page
          end
        else
          pdf.draw_text text, at: [x, y], size:
        end
      end
    rescue => e
      Rails.logger.error "Failed to generate datestamp file: #{e.message}"
      raise
    end
    # rubocop:enable Metrics/ParameterLists

    def stamp(file_path, stamp_path, multistamp: false)
      out_path = "#{Common::FileHelpers.random_file_path}.pdf"
      if multistamp
        PdfFill::Filler::PDF_FORMS.multistamp(file_path, stamp_path, out_path)
      else
        PdfFill::Filler::PDF_FORMS.stamp(file_path, stamp_path, out_path)
      end
      File.delete(file_path)
      out_path
    rescue
      Common::FileHelpers.delete_file_if_exists(out_path)
      raise
    end
  end
end
