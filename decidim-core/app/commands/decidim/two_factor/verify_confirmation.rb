# frozen_string_literal: true

module Decidim
  module TwoFactor
    # Checks the password or the code answering a confirmation challenge.
    class VerifyConfirmation < Decidim::Command
      # Public: Initializes the command.
      #
      # user - The user confirming the access.
      # challenge - The confirmation challenge being answered.
      # form - The challenge form of the method being answered.
      # password - The password typed instead of a code, if any.
      # password_allowed - Whether the organization signs users in with a password.
      def initialize(user, challenge, form, password: nil, password_allowed: true)
        @user = user
        @challenge = challenge
        @form = form
        @password = password
        @password_allowed = password_allowed
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when the password or the code matched.
      # - :wrong_password if the password did not match and attempts remain.
      # - :invalid if the code did not match and attempts remain.
      # - :exhausted if the attempts ran out, now or earlier.
      # - :expired if the challenge is no longer active.
      #
      # Returns nothing.
      def call
        return broadcast(:exhausted) if user.two_factor_challenges.exhausted.exists?(purpose: "confirmation")
        return verify_password if password.present?

        result = :invalid

        VerifyChallenge.call(challenge, form) do
          on(:ok) { result = :ok }
          on(:exhausted) { result = :exhausted }
          on(:expired) { result = :expired }
        end

        broadcast(result)
      end

      private

      attr_reader :user, :challenge, :form, :password, :password_allowed

      # Password guesses spend challenge attempts too, so the password cannot be brute-forced here.
      def verify_password
        return broadcast(:ok) if password_allowed && user.valid_password?(password)
        return broadcast(:exhausted) unless challenge.register_attempt! && challenge.attempts_left?

        broadcast(:wrong_password)
      end
    end
  end
end
