# frozen_string_literal: true

require 'rails_helper'
require 'claims_api/v2/poa_pdf_constructor/organization'
require_relative '../../../../support/pdf_matcher'

describe ClaimsApi::V2::PoaPdfConstructor::Organization do
  let(:temp) { create(:power_of_attorney, :with_full_headers) }

  before do
    Timecop.freeze(Time.zone.parse('2020-01-01T08:00:00Z'))
    temp.form_data = {
      veteran: {
        address: {
          numberAndStreet: '2719 Hyperion Ave',
          city: 'Los Angeles',
          state: 'CA',
          country: 'US',
          zipFirstFive: '92264'
        },
        phone: {
          areaCode: '555',
          phoneNumber: '5551337'
        },
        email: 'test@example.com'
      },
      claimant: {
        firstName: 'Lillian',
        middleInitial: 'A',
        lastName: 'Disney',
        email: 'lillian@disney.com',
        relationship: 'Spouse',
        address: {
          numberAndStreet: '2688 S Camino Real',
          city: 'Palm Springs',
          state: 'CA',
          country: 'US',
          zipFirstFive: '92264'
        },
        phone: {
          areaCode: '555',
          phoneNumber: '5551337'
        }
      },
      serviceOrganization: {
        poaCode: '456',
        firstName: 'Bob',
        lastName: 'Representative',
        organizationName: 'I Help Vets LLC',
        address: {
          numberAndStreet: '2719 Hyperion Ave',
          city: 'Los Angeles',
          state: 'CA',
          country: 'US',
          zipFirstFive: '92264'
        },
        jobTitle: 'Veteran Service Officer',
        email: 'example@test.com'
      },
      recordConsent: true,
      consentAddressChange: true,
      consentLimits: ['DRUG ABUSE', 'SICKLE CELL']
    }
    temp.save
  end

  after do
    Timecop.return
  end

  it 'construct pdf' do
    power_of_attorney = ClaimsApi::PowerOfAttorney.find(temp.id)
    data = power_of_attorney.form_data.deep_merge(
      {
        'veteran' => {
          'firstName' => power_of_attorney.auth_headers['va_eauth_firstName'],
          'lastName' => power_of_attorney.auth_headers['va_eauth_lastName'],
          'ssn' => power_of_attorney.auth_headers['va_eauth_pnid'],
          'birthdate' => power_of_attorney.auth_headers['va_eauth_birthdate']
        },
        'text_signatures' => {
          'page2' => [
            {
              'signature' => "#{power_of_attorney.auth_headers['va_eauth_firstName']} " \
                             "#{power_of_attorney.auth_headers['va_eauth_lastName']} - signed via api.va.gov",
              'x' => 35,
              'y' => 240
            },
            {
              'signature' => 'Bob Representative - signed via api.va.gov',
              'x' => 35,
              'y' => 200
            }
          ]
        }
      }
    )

    constructor = ClaimsApi::V2::PoaPdfConstructor::Organization.new
    expected_pdf = Rails.root.join('modules', 'claims_api', 'spec', 'fixtures', '21-22', 'v2',
                                   'signed_filled_final.pdf')
    generated_pdf = constructor.construct(data, id: power_of_attorney.id)
    expect(generated_pdf).to match_pdf_content_of(expected_pdf)
  end
end
