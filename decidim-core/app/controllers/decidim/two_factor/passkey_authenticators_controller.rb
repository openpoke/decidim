# frozen_string_literal: true

module Decidim
  module TwoFactor
    # Attaches a browser passkey through the WebAuthn registration ceremony.
    class PasskeyAuthenticatorsController < AuthenticatorsController
      def new
        enforce_permission_to(:update, :user, current_user:)

        @form = form(PasskeyEnrollmentForm).instance
        @registration_options = passkey_registration_options
      end

      def create
        enforce_permission_to(:update, :user, current_user:)

        @form = form(PasskeyEnrollmentForm).from_params(params)

        EnrollPasskey.call(current_user, @form, passkey_registration_ceremony) do
          on(:ok) { |recovery_codes| show_recovery_codes_or_redirect(recovery_codes, t(".success")) }

          on(:invalid) do
            flash[:alert] = t(".error")
            redirect_to new_two_factor_authentication_passkey_authenticator_path
          end
        end
      end

      private

      def two_factor_method = "passkey"

      def passkey_registration_options
        options = PasskeyAuthenticator.registration_options(current_user, request.base_url)
        session["decidim_two_factor_webauthn_registration"] = { "challenge" => options.challenge, "user_handle" => options.user.id }
        options
      end

      def passkey_registration_ceremony
        stored = session.delete("decidim_two_factor_webauthn_registration") || {}

        {
          relying_party: PasskeyAuthenticator.relying_party(current_organization, request.base_url),
          challenge: stored["challenge"],
          user_handle: stored["user_handle"]
        }
      end
    end
  end
end
