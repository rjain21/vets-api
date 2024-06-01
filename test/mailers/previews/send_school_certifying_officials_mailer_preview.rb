# frozen_string_literal: true

class SendSchoolCertifyingOfficialsMailerPreview < ActionMailer::Preview
  def build
    # def build(applicant, recipients, ga_client_id)
    claim = SavedClaim.where(type: 'SavedClaim::EducationBenefits::VA10203').last
    institution = GIDSRedis.new.get_institution_details_v0({ id: '11800020' })[:data][:attributes]
    scos = institution[:versioned_school_certifying_officials]
    emails = EducationForm::SendSchoolCertifyingOfficialsEmail.sco_emails(scos)

    SchoolCertifyingOfficialsMailer.build(claim.open_struct_form, emails, nil)
  end
end
