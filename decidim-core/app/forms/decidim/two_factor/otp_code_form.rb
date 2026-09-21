# frozen_string_literal: true

module Decidim
  module TwoFactor
    # A six-digit one-time code typed to answer a challenge or to confirm an enrollment.
    class OtpCodeForm < ChallengeForm
      mimic :challenge

      validates :code, presence: true, format: { with: /\A\d{6}\z/, allow_blank: true }

      def code
        super.gsub(/\s+/, "")
      end
    end
  end
end
