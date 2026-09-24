# frozen_string_literal: true

module Decidim
  module TwoFactor
    # Checks a submitted code against the login challenge and consumes it on success.
    class VerifyChallenge < Decidim::Command
      delegate :user, to: :challenge

      # Public: Initializes the command.
      #
      # challenge - The login challenge being answered.
      # form - The challenge form of the method being answered, with the code typed by the user.
      def initialize(challenge, form)
        @challenge = challenge
        @form = form
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok with the challenged user when the code matched.
      # - :invalid if the code did not match and attempts remain.
      # - :exhausted if there was no attempt left or the code did not match on the last one.
      # - :expired if the challenge is consumed, timed out or already exhausted.
      #
      # Returns nothing.
      def call
        return broadcast(:expired) if challenge.blank? || !challenge.active?

        unless challenge.register_attempt!
          notify_exhausted
          return broadcast(:exhausted)
        end

        if verified?
          return broadcast(:expired) unless challenge.consume!

          authenticator&.update!(last_used_at: Time.current)
          return broadcast(:ok, user)
        end

        return broadcast(:invalid) if challenge.attempts_left?

        notify_exhausted
        broadcast(:exhausted)
      end

      private

      attr_reader :challenge, :form

      def verified?
        return false if form.invalid?
        return RecoveryCode.redeem!(user, form.code) if form.recovery?

        authenticator.present? && authenticator.verify(form, challenge)
      end

      def authenticator
        return @authenticator if defined?(@authenticator)

        manifest = Decidim::TwoFactor.find_workflow_manifest(form.method_name)
        @authenticator = manifest && manifest.authenticator_class.find_for(user, form)
      end

      def notify_exhausted
        cache_key = "decidim/two_factor/exhausted_alert/#{user.id}"
        return if Rails.cache.exist?(cache_key)

        Rails.cache.write(cache_key, true, expires_in: Decidim.two_factor_alert_interval)
        TwoFactorMailer.attempts_exhausted(user).deliver_later
      end
    end
  end
end
