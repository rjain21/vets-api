# frozen_string_literal: true

require_relative 'base'
require_relative 'address'
require_relative 'telephone'
require_relative 'email'

module VAProfile
  module Models
    class ContactInformation < Base
      attribute :addresses, Array[Address]
      attribute :telephones, Array[Telephone]
      attribute :emails, Array[Email]

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
    end
  end
end
