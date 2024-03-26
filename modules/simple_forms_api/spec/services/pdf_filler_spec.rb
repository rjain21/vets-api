# frozen_string_literal: true

require 'rails_helper'
require SimpleFormsApi::Engine.root.join('spec', 'spec_helper.rb')

describe SimpleFormsApi::PdfFiller do
  def self.test_pdf_fill(form_number, test_payload = form_number)
    form_name = form_number.split(Regexp.union(%w[vba_ vha_]))[1].gsub('_', '-')
    context "when filling the pdf for form #{form_name} given template #{test_payload}" do
      it 'fills out a PDF from a templated JSON file' do
        expected_pdf_path = "tmp/#{form_number}-tmp.pdf"

        # remove the pdf if it already exists
        FileUtils.rm_f(expected_pdf_path)

        # fill the PDF
        data = JSON.parse(File.read("modules/simple_forms_api/spec/fixtures/form_json/#{test_payload}.json"))
        form = "SimpleFormsApi::#{form_number.titleize.gsub(' ', '')}".constantize.new(data)
        filler = SimpleFormsApi::PdfFiller.new(form_number:, form:)
        filler.generate
        expect(File.exist?(expected_pdf_path)).to eq(true)
      end
    end
  end

  test_pdf_fill 'vba_26_4555'
  test_pdf_fill 'vba_26_4555', 'vba_26_4555-min'
  test_pdf_fill 'vba_21_4142'
  test_pdf_fill 'vba_21_4142', 'vba_21_4142-min'
  test_pdf_fill 'vba_21_10210'
  test_pdf_fill 'vba_21_10210', 'vba_21_10210-min'
  test_pdf_fill 'vba_21p_0847'
  test_pdf_fill 'vba_21p_0847', 'vba_21p_0847-min'
  test_pdf_fill 'vba_21_0972'
  test_pdf_fill 'vba_21_0972', 'vba_21_0972-min'
  test_pdf_fill 'vba_21_0966'
  test_pdf_fill 'vba_21_0966', 'vba_21_0966-min'
  test_pdf_fill 'vba_40_0247'
  test_pdf_fill 'vba_40_0247', 'vba_40_0247-min'
  test_pdf_fill 'vha_10_7959c'

  # IVC CHAMPVA Forms
  test_pdf_fill 'vha_10_10d'
  test_pdf_fill 'vha_10_7959f_1'
  test_pdf_fill 'vha_10_7959f_2'

  def self.test_json_valid(mapping_file)
    it 'validates json is parseable' do
      expect do
        JSON.parse(File.read("modules/simple_forms_api/app/form_mappings/#{mapping_file}"))
      end.not_to raise_error
    end
  end

  test_json_valid 'vba_26_4555.json.erb'
  test_json_valid 'vba_21_4142.json.erb'
  test_json_valid 'vba_21_10210.json.erb'
  test_json_valid 'vba_21p_0847.json.erb'
  test_json_valid 'vba_21_0972.json.erb'
  test_json_valid 'vba_21_0966.json.erb'
  test_json_valid 'vba_40_0247.json.erb'
  test_json_valid 'vha_10_7959c.json.erb'

  # IVC CHAMPVA Forms
  test_json_valid 'vha_10_10d.json.erb'
  test_json_valid 'vha_10_7959f_1.json.erb'
  test_json_valid 'vha_10_7959f_2.json.erb'
end
