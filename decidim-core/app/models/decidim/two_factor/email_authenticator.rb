# frozen_string_literal: true

module Decidim
  module TwoFactor
    # The email one-time-code factor; its codes live on the login challenge.
    class EmailAuthenticator < Authenticator
      attribute :confirmed_at, default: -> { Time.current }

      def prepare_challenge(challenge)
        send_code(challenge) if challenge.code_digest.blank?
      end

      # Delivered inline so the plain code never reaches the job queue.
      def send_code(challenge)
        code = format("%06d", SecureRandom.random_number(10**6))
        challenge.update!(method_type: "email", code:)
        TwoFactorMailer.challenge_code(user, code, challenge.expires_at).deliver_now
      end

      def verify(form, challenge)
        challenge.valid_code?(form.code)
      end
    end
  end
end
