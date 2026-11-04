# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TwoFactor
    describe VerifyConfirmation do
      subject { described_class.new(user, challenge, form, password:, password_allowed:) }

      include_context "with a user holding an authenticator app"

      let(:user) { create(:user, :confirmed, password: "decidim123456789") }
      let(:challenge) { create(:two_factor_challenge, user:, purpose: "confirmation") }
      let(:code) { totp_code_for(secret) }
      let(:form) { OtpCodeForm.from_params(code:, method_name: "totp") }
      let(:password) { nil }
      let(:password_allowed) { true }

      context "when the code is right" do
        it "broadcasts ok" do
          expect { subject.call }.to broadcast(:ok)
        end
      end

      context "when the code is wrong" do
        let(:code) { "000000" }

        it "broadcasts invalid" do
          expect { subject.call }.to broadcast(:invalid)
        end
      end

      context "when the password is right" do
        let(:password) { "decidim123456789" }

        it "broadcasts ok without touching the challenge" do
          expect { subject.call }.to broadcast(:ok)
          expect(challenge.reload.attempts_count).to eq(0)
        end

        context "when the organization has no password sign-in" do
          let(:password_allowed) { false }

          it "broadcasts wrong_password and spends an attempt" do
            expect { subject.call }.to broadcast(:wrong_password)
            expect(challenge.reload.attempts_count).to eq(1)
          end
        end
      end

      context "when the password is wrong" do
        let(:password) { "wrong" }

        it "broadcasts wrong_password and spends an attempt" do
          expect { subject.call }.to broadcast(:wrong_password)
          expect(challenge.reload.attempts_count).to eq(1)
        end

        it "broadcasts exhausted on the last attempt" do
          challenge.update!(attempts_count: Decidim.two_factor_max_attempts - 1)

          expect { subject.call }.to broadcast(:exhausted)
        end
      end

      context "when the attempts already ran out" do
        before { challenge.update!(attempts_count: Decidim.two_factor_max_attempts) }

        it "broadcasts exhausted whatever is sent" do
          expect { subject.call }.to broadcast(:exhausted)
        end
      end
    end
  end
end
