# frozen_string_literal: true

module Decidim
  module TwoFactor
    # Puts a one-time code on the login challenge and mails it to the account email.
    class SendChallengeCode < Decidim::Command
      delegate :user, to: :challenge

      # Public: Initializes the command.
      #
      # challenge - The login challenge the code belongs to.
      def initialize(challenge)
        @challenge = challenge
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when the code was sent.
      # - :throttled if a code was already sent a moment ago.
      # - :invalid if the challenge is no longer active or the account has no
      #   email method attached.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if challenge.blank? || !challenge.active?
        return broadcast(:invalid) if authenticator.blank?
        return broadcast(:throttled) if throttled?

        authenticator.send_code(challenge)

        broadcast(:ok)
      end

      private

      attr_reader :challenge

      def authenticator
        @authenticator ||= EmailAuthenticator.find_for(user)
      end

      def throttled?
        challenge.code_digest.present? && challenge.updated_at > Decidim.two_factor_resend_interval.ago
      end
    end
  end
end
