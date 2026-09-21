# frozen_string_literal: true

module Decidim
  class TwoFactorMailerPreview < ActionMailer::Preview
    def challenge_code
      TwoFactorMailer.challenge_code(User.first, "123456")
    end

    def attempts_exhausted
      TwoFactorMailer.attempts_exhausted(User.first)
    end

    def factors_reset
      TwoFactorMailer.factors_reset(User.first)
    end
  end
end
