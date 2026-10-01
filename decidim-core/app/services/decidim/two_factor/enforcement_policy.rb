# frozen_string_literal: true

module Decidim
  module TwoFactor
    # Answers whether a user must set up a second factor; replaceable via
    # Decidim.two_factor_enforcement_policy.
    class EnforcementPolicy
      include Decidim::UserRoleChecker

      def initialize(user)
        @user = user
      end

      def challenge_required?
        organization.two_factor_authentication_enabled? && user.two_factor_enabled?
      end

      def setup_required?
        required? && !grace_active?
      end

      def setup_pending?
        required? && grace_active?
      end

      def grace_ends_at
        enforced_at = organization.two_factor_enforced_at
        return unless enforced_at

        [enforced_at, user.created_at].max + grace_period
      end

      private

      attr_reader :user

      delegate :organization, to: :user

      def required?
        return false unless organization.two_factor_authentication_enabled?
        return false if user.ephemeral? || user.managed?
        return false if user.two_factor_enabled?

        organization.two_factor_enforced_for_all? || (organization.two_factor_enforced_for_admins? && user_has_any_role?(user, broad_check: true))
      end

      def grace_active?
        ends_at = grace_ends_at

        ends_at.present? && ends_at.future?
      end

      # 0 disables the grace period, nil falls back to the installation default.
      def grace_period
        organization.two_factor_grace_period_days&.days || Decidim.two_factor_grace_period
      end
    end
  end
end
