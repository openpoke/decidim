# frozen_string_literal: true

module Decidim
  module TwoFactor
    # The verification step between a correct password and a second factor.
    class Challenge < ApplicationRecord
      self.table_name = "decidim_two_factor_challenges"

      belongs_to :user, foreign_key: "decidim_user_id", class_name: "Decidim::User"

      enum :purpose, { login: "login", confirmation: "confirmation" }

      attribute :expires_at, default: -> { Decidim.two_factor_code_expiry_time.from_now }

      validates :method_type, presence: true

      def self.issue_for(user, purpose:)
        pending = user.two_factor_challenges.active.find_by(purpose:)
        return pending if pending && !pending.credentials_changed?

        manifest = user.two_factor_attached_methods.first

        user.two_factor_challenges.create!(
          method_type: manifest&.name || "recovery",
          purpose:,
          metadata: { "authenticatable_salt" => user.authenticatable_salt }
        )
      end

      scope :active, -> { where(consumed_at: nil, expires_at: Time.current.., attempts_count: ...Decidim.two_factor_max_attempts) }
      scope :exhausted, -> { where(consumed_at: nil, expires_at: Time.current.., attempts_count: Decidim.two_factor_max_attempts..) }
      scope :stale, -> { where.not(consumed_at: nil).or(where(expires_at: ...Time.current)) }

      def active?
        consumed_at.nil? && !expired? && attempts_left?
      end

      def expired?
        expires_at.past?
      end

      def attempts_left?
        attempts_count < Decidim.two_factor_max_attempts
      end

      # Like the Devise session, the challenge dies with the password it was issued for.
      def credentials_changed?
        metadata["authenticatable_salt"] != user.authenticatable_salt
      end

      # Takes one attempt atomically, so concurrent submissions cannot slip
      # past the limit together; returns false when no attempt was left.
      def register_attempt!
        # rubocop:disable Rails/SkipsModelValidations
        taken = self.class.where(id:, consumed_at: nil, attempts_count: ...Decidim.two_factor_max_attempts)
                    .update_all("attempts_count = attempts_count + 1") == 1
        # rubocop:enable Rails/SkipsModelValidations
        reload if taken

        taken
      end

      # The WebAuthn ceremony lives on the challenge between the options and the assertion.
      def store_webauthn!(ceremony_challenge, origin)
        update!(metadata: metadata.merge("webauthn" => { "challenge" => ceremony_challenge, "origin" => origin }))
      end

      def take_webauthn!
        ceremony = metadata["webauthn"] || {}
        update!(metadata: metadata.except("webauthn"))
        ceremony
      end

      # Consumes the challenge atomically: only one of two concurrent right codes wins.
      def consume!
        # rubocop:disable Rails/SkipsModelValidations
        consumed = self.class.where(id:, consumed_at: nil).update_all(consumed_at: Time.current) == 1
        # rubocop:enable Rails/SkipsModelValidations
        reload if consumed

        consumed
      end

      def valid_code?(plain_code)
        CodeDigest.match?(code_digest, plain_code.to_s.strip)
      end

      def code=(plain_code)
        self.code_digest = CodeDigest.create(plain_code)
      end
    end
  end
end
