# frozen_string_literal: true

module Decidim
  module TwoFactor
    # The WebAuthn credential the browser returned, posted as a JSON string.
    module HasPasskeyCredential
      extend ActiveSupport::Concern

      included do
        attribute :credential, String

        validates :credential, presence: true
        validate :credential_shape

        # Defined on the class itself: a module reader would sit behind the generated one.
        def credential
          parsed = JSON.parse(super.to_s)
          parsed if parsed.is_a?(Hash)
        rescue JSON::ParserError
          nil
        end
      end

      private

      # The fields the WebAuthn library reads before it validates anything.
      def credential_shape
        return if credential.blank?
        return if credential["type"] == "public-key" && credential.values_at("id", "rawId").all?(String) && credential_response_present?

        errors.add(:credential, :invalid)
      end

      def credential_response_present?
        response = credential["response"]
        response.is_a?(Hash) && response.values_at(*credential_response_fields).all?(String)
      end
    end
  end
end
