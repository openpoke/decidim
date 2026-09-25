# frozen_string_literal: true

require "webauthn"

module Decidim
  module TwoFactor
    # Attaches a browser passkey once the WebAuthn registration ceremony verifies.
    class EnrollPasskey < EnrollAuthenticator
      # Public: Initializes the command.
      #
      # user - The user attaching the passkey.
      # form - A form object with the label typed by the user and the credential the browser returned.
      # ceremony - A hash with the :relying_party, :challenge and :user_handle of the pending ceremony.
      def initialize(user, form, ceremony)
        super(user)
        @form = form
        @ceremony = ceremony
      end

      protected

      def invalid? = form.invalid? || webauthn_credential.blank?

      def enroll
        PasskeyAuthenticator.create!(
          user:,
          name: form.name,
          external_id: webauthn_credential.id,
          public_key: webauthn_credential.public_key,
          sign_count: webauthn_credential.sign_count,
          confirmed_at: Time.current,
          metadata: { "user_handle" => ceremony[:user_handle], "transports" => Array(webauthn_credential.response.transports) }
        )
      end

      private

      attr_reader :form, :ceremony

      def webauthn_credential
        @webauthn_credential ||= verify_registration
      end

      def verify_registration
        return if ceremony[:challenge].blank?

        ceremony[:relying_party].verify_registration(form.credential, ceremony[:challenge], user_verification: true)
      rescue ::WebAuthn::Error, ArgumentError
        nil
      end
    end
  end
end
