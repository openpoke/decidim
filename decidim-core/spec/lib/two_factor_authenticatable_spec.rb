# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe TwoFactorAuthenticatable do
    let(:user) { create(:user, :confirmed) }

    describe "#two_factor_enabled?" do
      it "is not enabled while the factor is unconfirmed" do
        create(:totp_authenticator, user:)

        expect(user.two_factor_enabled?).to be(false)
      end

      it "is enabled once the factor is confirmed" do
        create(:totp_authenticator, :confirmed, user:)

        expect(user.two_factor_enabled?).to be(true)
      end
    end

    describe "#two_factor_attached_methods" do
      it "lists the methods attached to a user in the registry order" do
        create(:email_authenticator, user:)
        create(:totp_authenticator, :confirmed, user:)

        expect(user.two_factor_attached_methods.map(&:name)).to eq(%w(totp email))
      end
    end
  end
end
