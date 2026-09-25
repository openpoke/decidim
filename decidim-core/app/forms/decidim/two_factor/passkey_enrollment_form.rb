# frozen_string_literal: true

module Decidim
  module TwoFactor
    # The label typed by the user and the WebAuthn credential the browser returned for a new passkey.
    class PasskeyEnrollmentForm < Decidim::Form
      include HasPasskeyCredential

      attribute :name, String

      validates :name, length: { maximum: 64 }

      def name
        super.to_s.strip.presence
      end

      private

      def credential_response_fields = %w(clientDataJSON attestationObject)
    end
  end
end
