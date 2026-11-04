# frozen_string_literal: true

module Decidim
  # Mails the second-factor login codes and the related security alerts.
  class TwoFactorMailer < ApplicationMailer
    # The code lives as long as its challenge, which may already be running.
    def challenge_code(user, code, expires_at)
      @code = code
      @minutes_left = [((expires_at - Time.current) / 1.minute).ceil, 1].max
      deliver(user, "challenge_code")
    end

    def attempts_exhausted(user) = deliver(user, "attempts_exhausted")

    def factors_reset(user) = deliver(user, "factors_reset")

    private

    def deliver(user, key)
      with_user(user) do
        @user = user
        @organization = user.organization
        mail(to: user.email, subject: I18n.t("decidim.two_factor_mailer.#{key}.subject"))
      end
    end
  end
end
