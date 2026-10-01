# frozen_string_literal: true

require "active_support/concern"

module Decidim
  # Second-factor associations and predicates for Decidim::User.
  module TwoFactorAuthenticatable
    extend ActiveSupport::Concern

    included do
      has_many :two_factor_authenticators,
               class_name: "Decidim::TwoFactor::Authenticator",
               foreign_key: "decidim_user_id",
               dependent: :destroy
      has_many :two_factor_recovery_codes,
               class_name: "Decidim::TwoFactor::RecoveryCode",
               foreign_key: "decidim_user_id",
               dependent: :destroy
      has_many :two_factor_challenges,
               class_name: "Decidim::TwoFactor::Challenge",
               foreign_key: "decidim_user_id",
               dependent: :destroy
    end

    delegate :challenge_required?, :setup_required?, :setup_pending?, :grace_ends_at, to: :two_factor_enforcement_policy, prefix: :two_factor

    def two_factor_enabled?
      two_factor_authenticators.confirmed.exists?
    end

    # Reads the full registry: a method disabled after enrollment must keep working at login.
    def two_factor_attached_methods
      types = two_factor_authenticators.confirmed.pluck(:type).uniq
      order = Array(Decidim.two_factor_methods).map(&:to_s)

      Decidim::TwoFactor.workflows
                        .select { |manifest| types.include?(manifest.authenticator_class_name) }
                        .sort_by { |manifest| order.index(manifest.name) || order.size }
    end

    private

    def two_factor_enforcement_policy
      Decidim::TwoFactor.enforcement_policy.new(self)
    end
  end
end
