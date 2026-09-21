# frozen_string_literal: true

module Decidim
  module Devise
    # Custom Devise SessionsController to avoid namespace problems.
    class SessionsController < ::Devise::SessionsController
      include Decidim::DeviseControllers
      include Decidim::DeviseAuthenticationMethods

      before_action :check_sign_in_enabled, only: :create

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
