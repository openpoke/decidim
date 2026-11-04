# frozen_string_literal: true

module Decidim
  module Devise
    # Signs a user in with a passkey alone: the device proves both the key and the person.
    class PasskeySessionsController < ::DeviseController
      include FormFactory
      include Decidim::DeviseControllers
      include Decidim::DeviseAuthenticationMethods
      include Decidim::TwoFactor::FinishesLogin

      prepend_before_action :require_no_authentication
      before_action :ensure_passkey_sign_in_available

      def create
        TwoFactor::AuthenticatePasskey.call(current_organization, form(TwoFactor::PasskeyChallengeForm).from_params(params), session.delete("decidim_passkey_sign_in")) do
          on(:ok) { |user| finish_login(user) }

          on(:invalid) do
            flash[:alert] = t(".invalid")
            redirect_to new_user_session_path
          end
        end
      end

      private

      def ensure_passkey_sign_in_available
        head :not_found unless TwoFactor::PasskeyAuthenticator.sign_in_available?(current_organization)
      end
    end
  end
end
