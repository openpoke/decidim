# frozen_string_literal: true

module Decidim
  # Second-factor authentication: the registry of methods and module helpers.
  module TwoFactor
    include Decidim::HasWorkflows

    autoload :MethodManifest, "decidim/two_factor/method_manifest"

    def self.workflow_manifest_class = MethodManifest

    def self.available_methods(organization = nil)
      names = Array(Decidim.two_factor_methods).map(&:to_s)
      saved = Array(organization&.available_two_factor_methods)
      names &= saved if saved.any?

      names.filter_map { |name| find_workflow_manifest(name) }
    end

    def self.enforcement_policy
      Decidim.two_factor_enforcement_policy.to_s.constantize
    end

    # Deletes the remember-me cookie of this browser alone: the other devices stay remembered.
    def self.forget_remembered_login(cookies)
      return unless Decidim::User.respond_to?(:rememberable_options)

      options = Decidim::User.rememberable_options
      cookies.delete(options.fetch(:key, "remember_user_token"), ::Devise::Controllers::Rememberable.cookie_values.merge(options))
    end
  end
end
