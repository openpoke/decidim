# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe TwoFactorMailer do
    let(:user) { create(:user, :confirmed) }

    describe "challenge_code" do
      let(:mail) { described_class.challenge_code(user, "123456") }

      it "delivers the code to the account email" do
        expect(mail.to).to eq([user.email])
        expect(mail.subject).to eq("Your login verification code")
        expect(email_body(mail)).to include("123456")
      end
    end

    describe "attempts_exhausted" do
      let(:mail) { described_class.attempts_exhausted(user) }

      it "alerts the account email" do
        expect(mail.to).to eq([user.email])
        expect(mail.subject).to eq("A login attempt to your account was blocked")
        expect(email_body(mail)).to include("too many wrong verification codes")
        expect(email_body(mail)).to include("Change your password")
      end
    end

    describe "factors_reset" do
      let(:mail) { described_class.factors_reset(user) }

      it "alerts the account email" do
        expect(mail.to).to eq([user.email])
        expect(mail.subject).to eq("Two-factor authentication was reset on your account")
        expect(email_body(mail)).to include("removed all the second factors")
        expect(email_body(mail)).to include("Set up a new second factor")
      end
    end
  end
end
