D = Steep::Diagnostic
target :lib do
  signature 'sig/models/concerns'
  signature 'sig/disability_compensation/providers'
  signature 'sig/disability_compensation/responses'

  check 'app/models/concerns/form526_claim_fast_tracking_concern.rb'

  configure_code_diagnostics(D::Ruby.default)
end
