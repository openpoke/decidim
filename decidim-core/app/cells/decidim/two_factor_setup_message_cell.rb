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
      return if two_factor_setup_bypassed?(user)
      return if is_active_link?(decidim.two_factor_authentication_path)
      return unless user.two_factor_setup_pending?

      render :show
    end
  end
end
