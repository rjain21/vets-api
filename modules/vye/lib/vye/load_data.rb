# frozen_string_literal: true

module Vye
  class UserProfileConflict < StandardError; end
  class UserProfileNotFound < StandardError; end

  class LoadData
    STATSD_PREFIX = name.gsub('::', '.').underscore
    STATSD_NAMES =
      {
        team_sensitive_load_fail: "#{STATSD_PREFIX}.team_sensitive.load_fail",
        tims_feed_load_fail: "#{STATSD_PREFIX}.tims_feed.load_fail",
        bdn_feed_load_fail: "#{STATSD_PREFIX}.bdn_feed.load_fail",
        user_profile_created: "#{STATSD_PREFIX}.user_profile.created",
        user_profile_updated: "#{STATSD_PREFIX}.user_profile.updated"
      }.freeze

    SOURCES = %i[team_sensitive tims_feed bdn_feed].freeze

    private_constant :SOURCES

    private

    attr_reader :bdn_clone, :locator, :user_profile, :user_info, :source

    def initialize(source:, locator:, bdn_clone: nil, records: {})
      raise ArgumentError, format('Invalid source: %<source>s', source:) unless sources.include?(source)
      raise ArgumentError, 'Missing profile' if records[:profile].blank?
      raise ArgumentError, 'Missing bdn_clone' unless source == :tims_feed || bdn_clone.present?

      @bdn_clone = bdn_clone
      @locator = locator
      @source = source

      UserProfile.transaction do
        send(source, **records)
      end

      @valid_flag = true
    rescue => e
      error_message = e.message
      Rails.logger.error format(
        <<~FAILURE_TEMPLATE_HEREDOC.gsub(/\n/, ' ').freeze,
          Loading data failed:
          source: %<source>s,
          locator: %<locator>s,
          error message: %<error_message>s
        FAILURE_TEMPLATE_HEREDOC
        source:, locator:, error_message:
      )
      StatsD.increment(STATSD_NAMES[:"#{source}_load_fail"])
      Sentry.capture_exception(e)
      @valid_flag = false
    end

    def sources = SOURCES

    def team_sensitive(profile:, info:, address:, awards: [], pending_documents: [])
      load_profile(profile)
      load_info(info)
      load_address(address)
      load_awards(awards)
      load_pending_documents(pending_documents)
    end

    def tims_feed(profile:, pending_document:)
      load_profile(profile)
      load_pending_document(pending_document)
    end

    def bdn_feed(profile:, info:, address:, awards: [])
      bdn_clone_line = locator
      load_profile(profile)
      load_info(info.merge(bdn_clone_line:))
      load_address(address)
      load_awards(awards)
    end

    def load_profile(attributes)
      user_profile = UserProfile.produce(attributes)

      if source == :tims_feed
        # we are not going to create a new record based of off the TIMS feed
        raise UserProfileNotFound if user_profile.new_record?

        # we are not updating a record conflict from TIMS
        raise UserProfileConflict if user_profile.changed?
      else
        # we are going to count the number of records created
        # this should be decreasing over time
        if user_profile.new_record?
          StatsD.increment(STATSD_NAMES[:user_profile_created])

        # we will update a record conflict from BDN (or TeamSensitive),
        # but need to investigate why this is happening
        elsif user_profile.changed?
          user_profile_id = user_profile.id
          changed_attributes = user_profile.changed_attributes

          Rails.logger.warn format(
            'UserProfile(%<user_profile_id>u) updated %<changed_attributes>p from BDN feed line: %<locator>s',
            user_profile_id:, changed_attributes:, locator:
          )

          StatsD.increment(STATSD_NAMES[:user_profile_updated])
        end

        user_profile.save!
      end

      @user_profile = user_profile
    end

    def load_info(attributes)
      @user_info = user_profile.user_infos.create!(attributes.merge(bdn_clone:))
    end

    def load_address(attributes)
      user_info.address_changes.create!(attributes)
    end

    def load_awards(awards)
      awards&.each do |attributes|
        user_info.awards.create!(attributes)
      end
    end

    def load_pending_document(attributes)
      user_profile.pending_documents.create!(attributes)
    end

    def load_pending_documents(pending_documents)
      pending_documents.each do |attributes|
        user_profile.pending_documents.create!(attributes)
      end
    end

    public

    attr_reader :error_message

    def valid?
      @valid_flag
    end
  end
end
