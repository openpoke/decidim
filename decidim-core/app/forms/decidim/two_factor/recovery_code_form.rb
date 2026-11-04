# frozen_string_literal: true

module Decidim
  module TwoFactor
    # A recovery code typed to answer a challenge when no other method is at hand.
    class RecoveryCodeForm < ChallengeForm
      mimic :challenge

      validates :code, presence: true, format: { with: RecoveryCode::FORMAT, allow_blank: true }

      def recovery? = true
    end
  end
end
