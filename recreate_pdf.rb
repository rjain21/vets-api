require 'central_mail/datestamp_pdf'

root_dir = './Pension_PDF_Recreate'

failed_claims = []

['P1A','P1B'].each do |run_id|
  input = JSON.parse(File.read("#{root_dir}/#{run_id}/#{run_id}_form_data.json"))
  csv = CSV.read("#{root_dir}/#{run_id}/#{run_id}_submissions.csv",headers:true)
  created_at_hash = {}
  csv.each do |entry|
    created_at_hash[entry['va_gov_submission_id']] = DateTime.parse entry['va_gov_submission_created_at'].to_s
  end

  input['submissions'].each do |submission|
    # Load the claim into Active Record
    form_json = submission['details']
    temp_claim = SavedClaim::Pension.new(form:form_json.to_json.to_s, created_at: created_at_hash[submission['id'].to_s])
    temp_claim.save

    # Get the usable claim from Active Record
    claim = SavedClaim::Pension.last

    # find the zip
    zip_path_and_name = "#{root_dir}/#{run_id}/#{submission['id']}.zip"

    Zip::File.open(zip_path_and_name, create: true) do |zipfile|
      # generate pdf
      path_to_pdf = claim.to_pdf
      # determine actual submission timestamp
      timestamp = created_at_hash[submission['id'].to_s]
      # Stamp every page at bottom left
      stamped_path1 = CentralMail::DatestampPdf.new(path_to_pdf).run(text: 'VA.GOV', x: 5, y: 5, timestamp:)
      # Stamp Top with FDC reviewed
      stamped_path2 = CentralMail::DatestampPdf.new(stamped_path1).run(
        text: 'FDC Reviewed - va.gov Submission',
        x: 400,
        y: 770,
        text_only: true
      )
      # Stampe VA Date Stamp
      final_path = CentralMail::DatestampPdf.new(stamped_path2).run(
        text: 'Application Submitted on va.gov',
        x: 440,
        y: 685,
        text_only: true,
        timestamp:,
        size: 9,
        page_number: 0,
        template: "lib/pdf_fill/forms/pdfs/21P-527EZ.pdf",
        multistamp: true
      )
      # Put the new PDF in the Zip file, overwriting the invalid one
      zipfile.add("21P-527EZ_#{submission['id']}.pdf", final_path)
    end
  rescue => e
    failed_claims << {run_id: run_id, id: submission['id'], reason: e }
  end
end
pp failed_claims
