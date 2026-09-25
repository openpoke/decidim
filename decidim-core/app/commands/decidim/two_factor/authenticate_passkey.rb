# frozen_string_literal: true

module Decidim
  module TwoFactor
    # Finds the user behind a passkey used without a password and checks that
    # the device proved the person (fingerprint, face or PIN).
    class AuthenticatePasskey < Decidim::Command
      # Public: Initializes the command.
      #
      # organization - The organization the user signs in to.
      # form - A form object with the credential the browser returned.
      # ceremony - A hash with the "challenge", "origin" and "expires_at" of the pending sign in, if any.
      def initialize(organization, form, ceremony)
        @organization = organization
        @form = form
        @ceremony = ceremony || {}
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok with the user when the passkey proved them.
      # - :invalid for any failure, without telling which one.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid? || ceremony_expired?

        authenticator = PasskeyAuthenticator.authenticate(organization, form.credential, ceremony)
        return broadcast(:invalid) if authenticator.blank? || authenticator.user.blocked? || authenticator.user.deleted?

        authenticator.update!(last_used_at: Time.current)
        broadcast(:ok, authenticator.user)
      end

      private

      attr_reader :organization, :form, :ceremony

      def ceremony_expired?
        expires_at = Time.zone.parse(ceremony["expires_at"].to_s)

        expires_at.nil? || expires_at.past?
      end
    end
  end
end
