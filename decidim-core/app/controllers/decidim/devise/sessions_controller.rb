# frozen_string_literal: true

module Decidim
  module Devise
    # Custom Devise SessionsController to avoid namespace problems.
    class SessionsController < ::Devise::SessionsController
      include Decidim::DeviseControllers
      include Decidim::DeviseAuthenticationMethods

      before_action :check_sign_in_enabled, only: :create

      helper_method :passkey_sign_in_options

      rescue_from ActionController::InvalidAuthenticityToken, with: :redirect_to_referer_or_path

      def create
        super do |user|
          store_onboarding_cookie_data!(user)
        end
      end

      def destroy
        current_user.invalidate_all_sessions!
        if params[:translation_suffix].present?
          super { set_flash_message! :notice, params[:translation_suffix], { scope: "decidim.devise.sessions" } }
        else
          super
        end
      end

      def after_sign_out_path_for(user)
        request.referer || super
      end

      private

      # Issued with the page, so no other request of the page can overwrite the session holding the challenge.
      def passkey_sign_in_options
        options = TwoFactor::PasskeyAuthenticator.sign_in_options(current_organization, request.base_url)
        session["decidim_passkey_sign_in"] = {
          "challenge" => options.challenge,
          "origin" => request.base_url,
          "expires_at" => Decidim.two_factor_code_expiry_time.from_now.iso8601
        }
        options
      end

      def redirect_to_referer_or_path
        set_flash_message(:alert, "csrf_token", scope: "devise.failure")
        redirect_back_or_to(root_path) && return
      end

      def check_sign_in_enabled
        redirect_to new_user_session_path unless current_organization.sign_in_enabled?
      end
    end
  end
end
