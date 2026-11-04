# frozen_string_literal: true

module Decidim
  # The identity check (password or an attached second factor) guarding
  # sensitive changes on the two-factor settings page.
  class TwoFactorConfirmationsController < Decidim::ApplicationController
    include Decidim::UserProfile
    include TwoFactor::NeedsConfirmation

    before_action :ensure_two_factor_enabled
    before_action :ensure_attempts_left

    def show
      enforce_permission_to(:read, :user, current_user:)

      prepare_challenge
    end

    def create
      enforce_permission_to(:update, :user, current_user:)

      confirm_two_factor_access do
        pending = pending_action
        session.delete("decidim_two_factor_pending_action")

        if pending && pending["method"] == "GET"
          redirect_to pending["path"]
        else
          flash[:notice] = t("confirmed", scope: "decidim.two_factor_confirmations.show")
          redirect_to two_factor_authentication_path
        end
      end
    end

    def send_code
      enforce_permission_to(:update, :user, current_user:)

      super
    end

    private

    def ensure_two_factor_enabled
      redirect_to two_factor_authentication_path unless current_user.two_factor_enabled?
    end

    def ensure_attempts_left
      return unless current_user.two_factor_challenges.exhausted.exists?(purpose: "confirmation")

      exhaust_two_factor_confirmation
      redirect_to two_factor_authentication_path
    end
  end
end
