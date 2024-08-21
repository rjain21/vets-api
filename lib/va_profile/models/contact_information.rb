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
      attr_accessor :emails, :telephones, :addresses

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

      # Converts an instance of the ContactInformation model to a JSON
      # encoded string suitable for use in the body of a request to VAProfile
      # @return [String] JSON-encoded string suitable for requests to VAProfile
      def in_json
        {
          vet360Id: vet360_id,
          bio: {
            addresses: addresses,
            telephones: telephones,
            emails: emails,
          }
        }.to_json
      end

      private

      def valid_email_addresses
        emails.each do |email_hash|
          email = Email.new(email_hash)
          errors.add(:emails, 'contains invalid email') unless email.valid?
        end
      end

      def valid_phone_numbers
        telephones.each do |telephone_hash|
          telephone = Telephone.new(telephone_hash)
          errors.add(:telephones, 'contains invalid phone number') unless telephone.valid?
        end
      end

      def valid_addresses
        addresses.each do |address_hash|
          address = Address.new(address_hash)
          errors.add(:addresses, 'contains invalid address') unless address.valid?
        end
      end
    end
  end
end
