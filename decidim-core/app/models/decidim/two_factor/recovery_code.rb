# frozen_string_literal: true

module Decidim
  module TwoFactor
    # A one-time recovery code, stored as a digest.
    class RecoveryCode < ApplicationRecord
      self.table_name = "decidim_two_factor_recovery_codes"

      FORMAT = /\A\h{32}\z/

      belongs_to :user, foreign_key: "decidim_user_id", class_name: "Decidim::User"

      validates :code_digest, presence: true

      scope :unused, -> { where(used_at: nil) }

      # The codes are 128 random bits, so a keyed hash protects them as well as
      # a slow one and lets a code be looked up directly.
      def self.digest(plain_code)
        OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, plain_code.to_s.strip.downcase)
      end

      # Consumes the code at most once even when it is redeemed concurrently.
      def self.redeem!(user, plain_code)
        # rubocop:disable Rails/SkipsModelValidations
        unused.where(user:, code_digest: digest(plain_code)).update_all(used_at: Time.current, updated_at: Time.current) == 1
        # rubocop:enable Rails/SkipsModelValidations
      end
    end
  end
end
