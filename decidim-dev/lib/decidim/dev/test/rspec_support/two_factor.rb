# frozen_string_literal: true

require "rotp"

module Decidim
  module TwoFactorTestHelpers
    def totp_code_for(secret)
      ROTP::TOTP.new(secret).now
    end

    def stub_email_code(code = 123_456)
      allow(SecureRandom).to receive(:random_number).and_call_original
      allow(SecureRandom).to receive(:random_number).with(10**6).and_return(code)
    end
  end
end

RSpec.configure do |config|
  config.include Decidim::TwoFactorTestHelpers
end
