# frozen_string_literal: true

require_relative 'base'
require_relative 'address'
require_relative 'telephone'
require_relative 'email'

module VAProfile
  module Models
    class ContactInformation < Base
      include ActiveModel::Model
      attr_accessor :emails, :telephones, :addresses

      attribute :addresses, Array[Address]
      attribute :telephones, Array[Telephone]
      attribute :emails, Array[Email]

      validate :valid_email_addresses, if: -> { emails.present? }
      validate :valid_phone_numbers, if: -> { telephones.present? }
      validate :valid_addresses, if: -> { addresses.present? }

      # Converts an instance of the ContactInformation model to a JSON encoded string suitable for use in
      # the body of a request to VAProfile
      # @return [String] JSON-encoded string suitable for requests to VAProfile
      def in_json
        {
          bio: {
            addresses: addresses.map(&:to_hash),
            telephones: telephones.map(&:to_hash),
            emails: emails.map(&:to_hash)
          }
        }.to_json
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
    end
  end
end
