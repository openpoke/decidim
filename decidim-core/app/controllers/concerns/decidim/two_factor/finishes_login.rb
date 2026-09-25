# frozen_string_literal: true

module Decidim
  module TwoFactor
    # Starts the session once the second factor, or a passkey standing for both factors, is proven.
    module FinishesLogin
      extend ActiveSupport::Concern

      private

      def finish_login(user, remember_me: false)
        return_to = stored_location_for(:user)
        reset_session
        user.remember_me = true if remember_me && user.respond_to?(:remember_me=)
        sign_in(user, scope: :user, two_factor: :verified)
        store_location_for(:user, return_to)
        store_onboarding_cookie_data!(user)

        flash[:notice] = t("devise.sessions.signed_in")
        redirect_to after_sign_in_path_for(user)
      end
    end
  end
end
