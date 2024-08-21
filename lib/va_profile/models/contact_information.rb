# frozen_string_literal: true
require 'json'

require_relative 'base'
require_relative 'address'
require_relative 'telephone'
require_relative 'email'

module VAProfile
  module Models
    class ContactInformation < Base
      include VAProfile::Concerns::Defaultable
      include ActiveModel::Model
      attr_accessor :emails, :telephones, :addresses, :permissions

      attribute :created_at, Common::ISO8601Time
      attribute :addresses, Array[Address]
      attribute :telephones, Array[Telephone]
      attribute :emails, Array[Email]
      attribute :effective_end_date, Common::ISO8601Time
      attribute :effective_start_date, Common::ISO8601Time
      attribute :id, Integer
      attribute :source_date, Common::ISO8601Time
      attribute :source_system_user, String
      attribute :transaction_id, String
      attribute :updated_at, Common::ISO8601Time
      attribute :vet360_id, String

      validate :valid_email_addresses, if: -> { emails.present? }
      validate :valid_phone_numbers, if: -> { telephones.present? }
      validate :valid_addresses, if: -> { addresses.present? }
      validate :valid_permissions, if: -> { permissions.present? }

      # Converts an instance of the ContactInformation model to a JSON
      # encoded string suitable for use in the body of a request to VAProfile
      # @return [String] JSON-encoded string suitable for requests to VAProfile
      def in_json
        {
          vet360Id: vet360_id,
          bio: {
            addresses: for_json(@addresses),
            telephones: for_json(@telephones),
            emails: for_json(@emails),
            permissions: for_json(@permissions),
          }
        }.to_json
      end

      def addresses=(value)
        @addresses = value.map do |address|
          address.is_a?(Hash) ? Address.new(address) : address
        end
      end

      def emails=(value)
        @emails = value.map do |email|
          email.is_a?(Hash) ? Email.new(email) : email
        end
      end

      def telephones=(value)
        @telephones = value.map do |telephone|
          telephone.is_a?(Hash) ? Telephone.new(telephone) : telephone
        end
      end

      def permissions=(value)
        @permissions = value.map do |permission|
          permission.is_a?(Hash) ? Permission.new(permission) : permission
        end
      end

      private

      def valid_email_addresses
        emails.each do |email|
          errors.add(:emails, 'contains invalid email') unless email.valid?
        end
      end

      def valid_phone_numbers
        telephones.each do |telephone|
          errors.add(:telephones, 'contains invalid phone number') unless telephone.valid?
        end
      end

      def valid_addresses
        addresses.each do |address|
          errors.add(:addresses, 'contains invalid address') unless address.valid?
        end
      end

      def valid_permissions
        permissions.each do |permission|
          errors.add(:permissions, 'contains invalid permissions') unless permission.valid?
        end
      end

      private

      def for_json(attrs)
        attrs.map{|attr| JSON.parse(attr.in_json)['bio']}
      end

    end
  end
end
