# frozen_string_literal: true

require 'disability_compensation/requests/form526_request_body'

module EVSS
  module DisabilityCompensationForm
    class Form526ToLighthouseTransform
      # takes known EVSS Form526Submission format and converts it to a Lighthouse request body
      # evss_data will look like JSON.parse(form526_submission.form_data)
      def transform(evss_data)
        form526 = evss_data['form526']
        lh_request_body = Requests::Form526.new
        lh_request_body.claimant_certification = true
        lh_request_body.claim_date = form526['claimDate'] if form526['claimDate']
        lh_request_body.claim_process_type = evss_claims_process_type(form526) # basic_info[:claim_process_type]

        veteran = form526['veteran']
        lh_request_body.veteran_identification = transform_veteran(veteran)
        lh_request_body.change_of_address = transform_change_of_address(veteran) if veteran['changeOfAddress'].present?
        lh_request_body.homeless = transform_homeless(veteran) if veteran['homelessness'].present?

        service_information = form526['serviceInformation']
        lh_request_body.service_information = transform_service_information(service_information)

        disabilities = form526['disabilities']
        lh_request_body.disabilities = transform_disabilities(disabilities)

        direct_deposit = form526['directDeposit']
        lh_request_body.direct_deposit = transform_direct_deposit(direct_deposit) if direct_deposit.present?

        treatments = form526['treatments']
        lh_request_body.treatments = transform_treatments(treatments) if treatments.present?

        service_pay = form526['servicePay']
        lh_request_body.service_pay = transform_service_pay(service_pay) if service_pay.present?

        lh_request_body
      end

      # returns "STANDARD_CLAIM_PROCESS", "BDD_PROGRAM", or "FDC_PROGRAM"
      # based off of a few attributes in the evss data
      def evss_claims_process_type(form526)
        if form526['bddQualified']
          return 'BDD_PROGRAM'
        elsif form526['standardClaim']
          return 'STANDARD_CLAIM_PROCESS'
        end

        'FDC_PROGRAM'
      end

      def transform_veteran(veteran)
        veteran_identification = Requests::VeteranIdentification.new
        veteran_identification.current_va_employee = veteran['currentlyVAEmployee']
        veteran_identification.service_number = veteran['serviceNumber']
        veteran_identification.email_address = Requests::EmailAddress.new
        veteran_identification.email_address.email = veteran['emailAddress']
        veteran_identification.veteran_number = Requests::VeteranNumber.new

        fill_phone_number(veteran, veteran_identification)

        transform_mailing_address(veteran, veteran_identification) if veteran['currentMailingAddress'].present?

        veteran_identification
      end

      def transform_change_of_address(veteran)
        change_of_address = Requests::ChangeOfAddress.new
        change_of_address_source = veteran['changeOfAddress']
        change_of_address.city = change_of_address_source['militaryPostOfficeTypeCode'] ||
                                 change_of_address_source['city']
        change_of_address.state = change_of_address_source['militaryStateCode'] || change_of_address_source['state']
        change_of_address.country = change_of_address_source['country']
        change_of_address.address_line_1 = change_of_address_source['addressLine1']
        change_of_address.address_line_2 = change_of_address_source['addressLine2']
        change_of_address.address_line_3 = change_of_address_source['addressLine3']

        change_of_address.zip_first_five = change_of_address_source['internationalPostalCode'] ||
                                           change_of_address_source['zipFirstFive']
        change_of_address.zip_last_four = change_of_address_source['zipLastFour']
        change_of_address.type_of_address_change = change_of_address_source['addressChangeType']
        change_of_address.dates = Requests::Dates.new

        fill_change_of_address(change_of_address_source, change_of_address)

        change_of_address
      end

      def transform_homeless(veteran)
        homeless = Requests::Homeless.new
        homelessness = veteran['homelessness']

        if homelessness['currentlyHomeless'].present?
          fill_currently_homeless(homelessness['currentlyHomeless'], homeless)
        end

        fill_risk_of_becoming_homeless(homelessness, homeless) if homelessness['homelessnessRisk'].present?

        homeless
      end

      def transform_service_information(service_information_source)
        service_information = Requests::ServiceInformation.new
        transform_service_periods(service_information_source, service_information)
        if service_information_source['confinements']
          transform_confinements(service_information_source,
                                 service_information)
        end
        if service_information_source['alternateName']
          transform_alternate_names(service_information_source,
                                    service_information)
        end
        if service_information_source['reservesNationalGuardService']
          transform_reserves_national_guard_service(service_information_source,
                                                    service_information)
          reserves_national_guard_service_source = service_information_source['reservesNationalGuardService']
          # Title10Activation == FederalActivation
          service_information.federal_activation = Requests::FederalActivation.new(
            anticipated_separation_date: reserves_national_guard_service_source['anticipatedSeparationDate'],
            activation_date: reserves_national_guard_service_source['title10ActivationDate']
          )
        end

        service_information
      end

      # Transforms EVSS treatments format into Lighthouse request treatments block format
      # @param treatments_source Array[{}] accepts a list of treatments in the EVSS treatments format
      def transform_treatments(treatments_source)
        treatments_source.map do |treatment|
          center = treatment['center']
          Requests::Treatment.new(
            treated_disability_names: treatment['treatedDisabilityNames'],
            center: Requests::Center.new(
              name: center['name'],
              state: center['state'],
              city: center['city']
            ),
            # LH spec says YYYY-DD or YYYY date format
            begin_date: convert_approximate_date(treatment['startDate'], short: true)
          )
        end
      end

      # Transforms EVSS service pay format into Lighthouse request service pay block format
      # @param service_pay_source {} accepts an object in the EVSS servicePay format
      def transform_service_pay(service_pay_source)
        # mapping to target <- source
        service_pay_target = Requests::ServicePay.new

        service_pay_target.favor_training_pay = service_pay_source['waiveVABenefitsToRetainTrainingPay']
        service_pay_target.favor_military_retired_pay = service_pay_source['waiveVABenefitsToRetainRetiredPay']

        # map military retired pay block
        if service_pay_source['militaryRetiredPay'].present?
          transform_military_retired_pay(service_pay_source, service_pay_target)
        end

        # map separation pay block
        transform_separation_pay(service_pay_source, service_pay_target) if service_pay_source['separationPay'].present?

        service_pay_target
      end

      private

      def transform_separation_pay(service_pay_source, service_pay_target)
        separation_pay_source = service_pay_source['separationPay']

        if separation_pay_source.present?
          service_pay_target.retired_status = service_pay_source['retiredStatus']&.upcase
        end
        service_pay_target.received_separation_or_severance_pay =
          convert_nullable_bool(separation_pay_source['received'])

        separation_pay_payment_source = separation_pay_source['payment'] if separation_pay_source.present?
        if separation_pay_payment_source.present?
          service_pay_target.separation_severance_pay = Requests::SeparationSeverancePay.new(
            date_payment_received: convert_approximate_date(separation_pay_source['receivedDate']),
            branch_of_service: separation_pay_payment_source['serviceBranch'],
            pre_tax_amount_received: separation_pay_payment_source['amount']
          )
        end
      end

      def transform_military_retired_pay(service_pay_source, service_pay_target)
        military_retired_pay_source = service_pay_source['militaryRetiredPay']

        service_pay_target.receiving_military_retired_pay =
          convert_nullable_bool(military_retired_pay_source['receiving'])
        service_pay_target.future_military_retired_pay =
          convert_nullable_bool(military_retired_pay_source['willReceiveInFuture'])

        military_retired_pay_payment_source = military_retired_pay_source['payment']
        if military_retired_pay_payment_source.present?
          service_pay_target.military_retired_pay = Requests::MilitaryRetiredPay.new(
            branch_of_service: military_retired_pay_payment_source['serviceBranch'],
            monthly_amount: military_retired_pay_payment_source['amount']
          )
        end
      end

      def transform_confinements(service_information_source, service_information)
        service_information.confinements = service_information_source['confinements'].map do |confinement|
          Requests::Confinement.new(
            approximate_begin_date: confinement['confinementBeginDate'],
            approximate_end_date: confinement['confinementEndDate']
          )
        end
      end

      def transform_alternate_names(service_information_source, service_information)
        service_information.alternate_names = service_information_source['alternateNames'].map do |alternate_name|
          "#{alternate_name['firstName']} #{alternate_name['middleName']} #{alternate_name['lastName']}"
        end
      end

      def transform_reserves_national_guard_service(service_information_source, service_information)
        reserves_national_guard_service_source = service_information_source['reservesNationalGuardService']
        initialize_reserves_national_guard_service(reserves_national_guard_service_source, service_information)

        sorted_service_periods = sorted_service_periods(service_information_source).filter do |service_period|
          service_period['serviceBranch'].downcase.include?('reserves') ||
            service_period['serviceBranch'].downcase.include?('national guard')
        end

        if sorted_service_periods.first.present?
          component = convert_to_service_component(sorted_service_periods.first['serviceBranch'])
        end
        service_information.reserves_national_guard_service.component = component
      end

      def initialize_reserves_national_guard_service(reserves_national_guard_service_source, service_information)
        service_information.reserves_national_guard_service = Requests::ReservesNationalGuardService.new(
          obligation_term_of_service: Requests::ObligationTermsOfService.new(
            begin_date: reserves_national_guard_service_source['obligationTermOfServiceFromDate'],
            end_date: reserves_national_guard_service_source['obligationTermOfServiceToDate']
          ),
          unit_name: reserves_national_guard_service_source['unitName'],
          receiving_inactive_duty_training_pay:
            convert_nullable_bool(reserves_national_guard_service_source['receivingInactiveDutyTrainingPay'])
        )

        if reserves_national_guard_service_source['unitPhone']
          service_information.reserves_national_guard_service.unit_phone = Requests::UnitPhone.new(
            area_code: reserves_national_guard_service_source['unitPhone']['areaCode'],
            phone_number: reserves_national_guard_service_source['unitPhone']['phoneNumber']
          )
        end
      end

      def transform_mailing_address(veteran, veteran_identification)
        veteran_identification.mailing_address = Requests::MailingAddress.new
        veteran_identification.mailing_address.address_line_1 = veteran['currentMailingAddress']['addressLine1']
        veteran_identification.mailing_address.address_line_2 = veteran['currentMailingAddress']['addressLine2']
        veteran_identification.mailing_address.address_line_3 = veteran['currentMailingAddress']['addressLine3']

        veteran_identification.mailing_address.city = veteran['currentMailingAddress']['militaryPostOfficeTypeCode'] ||
                                                      veteran['currentMailingAddress']['city']
        veteran_identification.mailing_address.state = veteran['currentMailingAddress']['militaryStateCode'] ||
                                                       veteran['currentMailingAddress']['state']
        veteran_identification.mailing_address.zip_first_five =
          veteran['currentMailingAddress']['internationalPostalCode'] ||
          veteran['currentMailingAddress']['zipFirstFive']
        veteran_identification.mailing_address.zip_last_four = veteran['currentMailingAddress']['zipLastFour']
        veteran_identification.mailing_address.country = veteran['currentMailingAddress']['country']
      end

      def transform_service_periods(service_information_source, service_information)
        sorted_service_periods = sorted_service_periods(service_information_source)

        service_information.service_periods = sorted_service_periods.map do |service_period|
          Requests::ServicePeriod.new(
            service_branch: service_period['serviceBranch'],
            active_duty_begin_date: service_period['activeDutyBeginDate'],
            active_duty_end_date: service_period['activeDutyEndDate'],
            service_component: convert_to_service_component(service_period['serviceBranch'])
          )
        end

        service_information.service_periods.first.separation_location_code =
          service_information_source['separationLocationCode']
      end

      def sorted_service_periods(service_information_source)
        service_information_source['servicePeriods'].sort_by do |service_period|
          service_period['activeDutyEndDate']
        end.reverse
      end

      # returns either 'Active', 'Reserves' or 'National Guard' based on the service branch
      def convert_to_service_component(service_branch)
        service_branch = service_branch.downcase
        return 'Reserves' if service_branch.include?('reserves')
        return 'National Guard' if service_branch.include?('national guard')

        'Active'
      end

      # convert EVSS date object format into YYYY-MM-DD lighthouse string format
      # @param approximate_date_source Hash EVSS format data object
      # @param short boolean (optional) return a shortened date YYYY-MM
      def convert_approximate_date(approximate_date_source, short: false)
        approximate_date = approximate_date_source['year'].to_s
        approximate_date += "-#{approximate_date_source['month']}" if approximate_date_source['month']

        # returns YYYY-MM if only "short" date is requested
        return approximate_date if short

        approximate_date += "-#{approximate_date_source['day']}" if approximate_date_source['day']

        approximate_date
      end

      def transform_disabilities(disabilities_source)
        disabilities_source.map do |disability_source|
          dis = Requests::Disability.new
          dis.disability_action_type = disability_source['disabilityActionType']
          dis.name = disability_source['name']
          dis.classification_code = disability_source['classificationCode'] if disability_source['classificationCode']
          dis.service_relevance = disability_source['serviceRelevance'] || ''
          if disability_source['approximateBeginDate']
            dis.approximate_date = convert_approximate_date(disability_source['approximateBeginDate'])
          end
          dis.rated_disability_id = disability_source['ratedDisabilityId'] if disability_source['ratedDisabilityId']
          dis.diagnostic_code = disability_source['diagnosticCode'] if disability_source['diagnosticCode']
          if disability_source['secondaryDisabilities']
            dis.secondary_disabilities = transform_secondary_disabilities(disability_source)
          end
          dis
        end
      end

      def transform_secondary_disabilities(disability_source)
        disability_source['secondaryDisabilities'].map do |secondary_disability_source|
          sd = Requests::SecondaryDisability.new
          sd.disability_action_type = 'SECONDARY'
          sd.name = secondary_disability_source['name']
          if secondary_disability_source['classificationCode']
            sd.classification_code = secondary_disability_source['classificationCode']
          end
          sd.service_relevance = secondary_disability_source['serviceRelevance'] || ''
          if secondary_disability_source['approximateBeginDate']
            sd.approximate_date = convert_approximate_date(secondary_disability_source['approximateBeginDate'])
          end
          sd
        end
      end

      def transform_direct_deposit(direct_deposit_source)
        direct_deposit = Requests::DirectDeposit.new
        if direct_deposit_source['bankName']
          direct_deposit.financial_institution_name = direct_deposit_source['bankName']
        end
        direct_deposit.account_type = direct_deposit_source['accountType'] if direct_deposit_source['accountType']
        direct_deposit.account_number = direct_deposit_source['accountNumber'] if direct_deposit_source['accountNumber']
        direct_deposit.routing_number = direct_deposit_source['routingNumber'] if direct_deposit_source['routingNumber']

        direct_deposit
      end

      # @param [Hash] veteran: veteran info in EVSS format
      # @param [Requests::Form526::VeteranIdentification] target: transform target
      def fill_phone_number(veteran, target)
        if veteran['daytimePhone'].present?
          target.veteran_number.telephone = veteran['daytimePhone']['areaCode'] +
                                            veteran['daytimePhone']['phoneNumber']
        end
      end

      def fill_change_of_address(change_of_address_source, change_of_address)
        # convert dates to YYYY-MM-DD
        if change_of_address_source['beginningDate'].present?
          change_of_address.dates.begin_date =
            convert_date(change_of_address_source['beginningDate'])
        end
        if change_of_address_source['endingDate'].present?
          change_of_address.dates.end_date =
            convert_date(change_of_address_source['endingDate'])
        end
      end

      # only needs currentlyHomeless from 'homelessness' source
      def fill_currently_homeless(source, target)
        options = source['homelessSituationType']&.strip
        send_other_description = options == 'OTHER'
        other_description = source['otherLivingSituation'] || nil
        target.currently_homeless = Requests::CurrentlyHomeless.new(
          homeless_situation_options: options,
          other_description: send_other_description ? other_description : nil
        )
      end

      # needs whole `homelessness` object source
      def fill_risk_of_becoming_homeless(source, target)
        target.risk_of_becoming_homeless = Requests::RiskOfBecomingHomeless.new(
          living_situation_options: source['homelessnessRisk']['homelessnessRiskSituationType'],
          other_description: source['homelessnessRisk']['otherLivingSituation']
        )
        target.point_of_contact = source['pointOfContact']['pointOfContactName']
        primary_phone = source['pointOfContact']['primaryPhone']
        target.point_of_contact_number = Requests::ContactNumber.new(
          telephone: primary_phone['areaCode'] + primary_phone['phoneNumber']
        )
      end

      def convert_nullable_bool(boolean_value)
        return 'YES' if boolean_value == true
        return 'NO' if boolean_value == false

        # placing nil may not be necessary
        nil
      end

      def convert_date(date)
        Date.parse(date).strftime('%Y-%m-%d')
      end
    end
  end
end
