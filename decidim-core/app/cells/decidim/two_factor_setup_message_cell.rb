# frozen_string_literal: true

module Decidim
  # This cell renders the invitation to set up the second factor while the
  # organization's grace period is running.
  #
  # The `model` is expected to be a user
  class TwoFactorSetupMessageCell < Decidim::ViewModel
    include ActiveLinkTo
    include Decidim::ActiveLinkToHelper
    include Decidim::TwoFactor::SetupHelper

    alias user model

    def show
      return if session["decidim_two_factor_banner_dismissed"].present?
      return if controller.two_factor_setup_bypassed?
      return if is_active_link?(setup_path)
      return unless user.two_factor_setup_pending?

      render :show
    end

    private

    def setup_path
      decidim.two_factor_authentication_path
    end
  end
end
