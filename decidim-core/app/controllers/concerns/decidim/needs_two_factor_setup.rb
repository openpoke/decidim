# frozen_string_literal: true

module Decidim
  # Shared behavior for redirecting users who must set up a second factor
  # once the organization's grace period is over.
  module NeedsTwoFactorSetup
    extend ActiveSupport::Concern

    included do
      before_action :check_two_factor_setup_required
    end

    private

    def check_two_factor_setup_required
      return unless current_user
      return if respond_to?(:current_user_impersonated?, true) && current_user_impersonated?
      # The session came through a provider trusted as a second factor.
      return if session["decidim_two_factor_bypassed"] == current_user.id
      return unless current_user.two_factor_setup_required?
      return if two_factor_setup_permitted_path?(request.path)

      return head(:forbidden) unless request.format.html?

      redirect_to_two_factor_setup
    end

    def redirect_to_two_factor_setup
      session["decidim_two_factor_return_to"] = request.path if request.get?
      flash[:notice] = flash[:notice] if flash[:notice]
      flash[:secondary] = t("decidim.two_factor_authentications.setup_required.alert")
      redirect_to decidim.two_factor_authentication_path
    end

    def two_factor_setup_permitted_path?(target_path)
      path = target_path.split("?").first

      return true if two_factor_setup_permitted_prefixes.any? { |prefix| path.starts_with?(prefix) }
      return true if request.delete? && path == decidim.account_path

      two_factor_setup_permitted_paths.any? { |el| el.split("?").first == path }
    end

    def two_factor_setup_permitted_prefixes
      ["#{decidim.two_factor_authentication_path}/", decidim.download_your_data_path, "/locale", "/manifest.webmanifest"]
    end

    def two_factor_setup_permitted_paths
      [decidim.two_factor_authentication_path,
       (tos_path if respond_to?(:tos_path, true)),
       decidim.delete_account_path,
       decidim.accept_tos_path,
       decidim.change_password_path].compact
    end
  end
end
