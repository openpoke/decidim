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
          authenticator_selection: { resident_key: "discouraged", user_verification: "preferred" }
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

      def self.find_for(user, form)
        confirmed.find_by(user:, external_id: form.credential&.dig("id"))
      end

      def self.user_handle_for(user)
        stored = user.two_factor_authenticators.find_by(type: name)&.metadata&.dig("user_handle")

        stored || ::WebAuthn.generate_user_id
      end

      def credential_descriptor
        { type: "public-key", id: external_id, transports: Array(metadata["transports"]).presence }.compact
      end

      def verify(form, challenge)
        ceremony = challenge.take_webauthn!
        return false if ceremony["challenge"].blank?

        webauthn_credential = self.class.relying_party(user.organization, ceremony["origin"]).verify_authentication(
          form.credential,
          ceremony["challenge"],
          public_key:,
          sign_count:
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
