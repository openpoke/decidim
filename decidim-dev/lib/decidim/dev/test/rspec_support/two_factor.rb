# frozen_string_literal: true

require "rotp"
require "webauthn"
require "webauthn/fake_client"

module Decidim
  module TwoFactorTestHelpers
    def totp_code_for(secret)
      ROTP::TOTP.new(secret).now
    end

    def stub_email_code(code = 123_456)
      allow(SecureRandom).to receive(:random_number).and_call_original
      allow(SecureRandom).to receive(:random_number).with(10**6).and_return(code)
    end

    def enroll_fake_passkey(user, fake_client, relying_party, user_handle: WebAuthn.generate_user_id)
      options = relying_party.options_for_registration(user: { id: user_handle, name: user.email })
      credential = fake_client.create(challenge: options.challenge).to_json
      form = Decidim::TwoFactor::PasskeyEnrollmentForm.from_params(name: "Key", credential:)

      Decidim::TwoFactor::EnrollPasskey.call(user, form, { relying_party:, challenge: options.challenge, user_handle: })
      Decidim::TwoFactor::PasskeyAuthenticator.confirmed.where(user:).last
    end

    def passkey_options_from_response
      JSON.parse(response.parsed_body.at_css("[data-controller='passkey']")["data-passkey-options-value"])
    end
  end
end

RSpec.configure do |config|
  config.include Decidim::TwoFactorTestHelpers
end
