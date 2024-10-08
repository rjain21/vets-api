# frozen_string_literal: true

module BGS
  class DependencyVerificationService
    include SentryLogging

    attr_reader :participant_id, :ssn, :common_name, :email, :icn, :user_uuid

    def initialize(user)
      @participant_id = user.participant_id
      @ssn = user.ssn
      @common_name = user.common_name
      @email = user.email
      @icn = user.icn
      @user_uuid = user.uuid
    end

    def read_diaries
      if participant_id.blank?
        Rails.logger.warn('read_diaries: participant_id is blank', { icn:, user_uuid: })
        return { dependency_decs: nil, diaries: [] }
      end

      diaries = service.diaries.read_diaries(
        {
          beneficiary_id: participant_id,
          participant_id:,
          ssn:,
          award_type: 'CPL'
        }
      )
      return empty_response(diaries) if diaries[:diaries].blank?

      dependency_decisions = diaries[:dependency_decs][:dependency_dec]
      diaries[:dependency_decs][:dependency_dec] = normalize_dependency_decisions(dependency_decisions)

      standard_response(diaries)
    rescue => e
      log_exception_to_sentry(e, { icn: }, { team: Constants::SENTRY_REPORTING_TEAM })
    end

    private

    def empty_response(diaries)
      {
        dependency_decs: diaries.dig(:dependency_decs, :dependency_dec),
        diaries: []
      }
    end

    def standard_response(diaries)
      {
        dependency_decs: diaries.dig(:dependency_decs, :dependency_dec),
        diaries: diaries.dig(:diaries, :diary)
      }
    end

    def normalize_dependency_decisions(dependency_decisions)
      set1 = dependency_decisions.delete_if do |dependency_decision|
        invalid_dependency_decision?(dependency_decision)
      end

      final = []
      return final if set1.blank?

      set2 = set1.group_by { |dependency_decision| dependency_decision[:person_id] }

      set2.each_value do |array|
        latest = array.max_by { |dd| dd[:award_effective_date] }
        final << latest if latest[:dependency_status_type] != 'NAWDDEP'
      end

      final
    end

    def service
      @service ||= BGS::Services.new(external_uid: icn, external_key:)
    end

    def external_key
      @external_key ||= begin
        key = common_name.presence || email
        key.first(Constants::EXTERNAL_KEY_MAX_LENGTH)
      end
    end

    def invalid_dependency_decision?(dependency_decision)
      !dependency_decision.is_a?(Hash) ||
        !dependency_decision.key?(:award_effective_date) ||
        dependency_decision[:award_effective_date].future?
    end
  end
end
