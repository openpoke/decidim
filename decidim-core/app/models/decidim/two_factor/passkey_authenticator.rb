# frozen_string_literal: true

require "webauthn"

module Decidim
  module TwoFactor
    # A WebAuthn credential, one row per device.
    class PasskeyAuthenticator < Authenticator
      extend Decidim::TranslationsHelper

      validates :external_id, presence: true, uniqueness: true
      validates :public_key, presence: true

      def self.relying_party(organization, origin)
        ::WebAuthn::RelyingParty.new(
          allowed_origins: [origin],
          id: organization.host,
          name: translated_attribute(organization.name, organization)
        )
      end

      def self.registration_options(user, origin)
        relying_party(user.organization, origin).options_for_registration(
          user: { id: user_handle_for(user), name: user.email, display_name: user.name },
          exclude_credentials: where(user:).map(&:credential_descriptor),
          authenticator_selection: { resident_key: "required", user_verification: "required" }
        )
      end

      def self.assertion_options(challenge, origin)
        options = relying_party(challenge.user.organization, origin).options_for_authentication(
          allow_credentials: confirmed.where(user: challenge.user).map(&:credential_descriptor),
          user_verification: "preferred"
        )
        challenge.store_webauthn!(options.challenge, origin)
        options
      end

      # Passkeys sign in on their own where the organization offers them as a second factor.
      def self.sign_in_available?(organization)
        organization.sign_in_enabled? && TwoFactor.available_methods(organization).any? { |manifest| manifest.name == "passkey" }
      end

      # No list of keys: the device offers the ones it holds for this site.
      def self.sign_in_options(organization, origin)
        relying_party(organization, origin).options_for_authentication(user_verification: "required")
      end

      # A passkey used without a password must belong to this organization and
      # to the user it names, and the device must have verified the person.
      def self.authenticate(organization, credential, ceremony)
        authenticator = confirmed.joins(:user).find_by(external_id: credential["id"], decidim_users: { decidim_organization_id: organization.id })
        return unless authenticator && credential.dig("response", "userHandle") == authenticator.metadata["user_handle"]

        authenticator if authenticator.verify_assertion(credential, ceremony, user_verification: true)
      end

      def self.find_for(user, form)
        confirmed.find_by(user:, external_id: form.credential&.dig("id"))
      end

      # Opaque and stable, so a new passkey replaces the one the device already holds for this account.
      def self.user_handle_for(user)
        Base64.urlsafe_encode64(OpenSSL::HMAC.digest("SHA256", Rails.application.secret_key_base, "passkey-#{user.id}"), padding: false)
      end

      def credential_descriptor
        { type: "public-key", id: external_id, transports: Array(metadata["transports"]).presence }.compact
      end

      def verify(form, challenge)
        verify_assertion(form.credential, challenge.take_webauthn!)
      end

      def verify_assertion(credential, ceremony, user_verification: false)
        return false if ceremony["challenge"].blank?

        webauthn_credential = self.class.relying_party(user.organization, ceremony["origin"]).verify_authentication(
          credential,
          ceremony["challenge"],
          public_key:,
          sign_count:,
          user_verification:
        )

        update!(sign_count: webauthn_credential.sign_count)
        true
      rescue ::WebAuthn::Error, ArgumentError
        false
      end

      def multiple_per_user? = true
    end
  end
end
