# frozen_string_literal: true

module Decidim
  module TwoFactor
    # The WebAuthn assertion the browser returned, to answer a challenge or to sign in.
    class PasskeyChallengeForm < ChallengeForm
      mimic :challenge

      include HasPasskeyCredential

      private

      def credential_response_fields = %w(clientDataJSON authenticatorData signature)
    end
  end
end
