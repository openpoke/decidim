# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TwoFactor
    describe EmailAuthenticator do
      let(:user) { create(:user, :confirmed) }
      let(:authenticator) { create(:email_authenticator, user:) }
      let(:challenge) { create(:two_factor_challenge, user:) }

      describe "#prepare_challenge" do
        context "when the challenge holds no code yet" do
          it "puts a code on the challenge and mails it" do
            expect { authenticator.prepare_challenge(challenge) }.to change { challenge.reload.code_digest }.from(nil)
            expect(last_email.to).to eq([user.email])
          end
        end

        context "when the challenge already holds a code" do
          before do
            authenticator.prepare_challenge(challenge)
            clear_emails
          end

          it "keeps the code and mails nothing" do
            expect { authenticator.prepare_challenge(challenge) }.not_to(change { challenge.reload.code_digest })
            expect(emails).to be_empty
          end
        end
      end

      describe "#verify" do
        let(:challenge) { create(:two_factor_challenge, user:, method_type: "email", code: "654321") }

        it "checks the code against the one on the challenge" do
          expect(authenticator.verify(OtpCodeForm.from_params(code: "654321"), challenge)).to be(true)
          expect(authenticator.verify(OtpCodeForm.from_params(code: "000000"), challenge)).to be(false)
        end
      end
    end
  end
end
