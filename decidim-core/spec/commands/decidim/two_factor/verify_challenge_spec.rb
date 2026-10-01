# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TwoFactor
    describe VerifyChallenge do
      subject { described_class.new(challenge, form) }

      include_context "with a user holding an authenticator app"

      let(:user) { create(:user, :confirmed) }
      let(:challenge) { create(:two_factor_challenge, user:) }
      let(:method_name) { "totp" }
      let(:code) { totp_code_for(secret) }
      let(:form) { OtpCodeForm.from_params(code:, method_name:) }

      context "when the authenticator app code is right" do
        it "broadcasts ok with the user, consumes the challenge and records the use" do
          expect { subject.call }.to broadcast(:ok, user)
          expect(challenge.reload.consumed_at).to be_present
          expect(authenticator.reload.last_used_at).to be_present
        end
      end

      context "when the code is wrong" do
        let(:code) { "000000" }

        it "broadcasts invalid and counts the attempt" do
          expect { subject.call }.to broadcast(:invalid)
          expect(challenge.reload.attempts_count).to eq(1)
        end
      end

      context "when the form is not valid" do
        let(:code) { "" }

        it "broadcasts invalid and counts the attempt" do
          expect { subject.call }.to broadcast(:invalid)
          expect(challenge.reload.attempts_count).to eq(1)
        end
      end

      context "when the email code is right" do
        let!(:email_method) { create(:email_authenticator, user:) }
        let(:challenge) { create(:two_factor_challenge, user:, method_type: "email", code: "654321") }
        let(:method_name) { "email" }
        let(:code) { "654321" }

        it "broadcasts ok with the user" do
          expect { subject.call }.to broadcast(:ok, user)
        end
      end

      context "when the email code is right but the email method is not attached" do
        let(:challenge) { create(:two_factor_challenge, user:, method_type: "email", code: "654321") }
        let(:method_name) { "email" }
        let(:code) { "654321" }

        it "broadcasts invalid" do
          expect { subject.call }.to broadcast(:invalid)
        end
      end

      context "when a recovery code is used" do
        let!(:recovery_codes) { RegenerateRecoveryCodes.call(user)[:ok] }
        let(:method_name) { "recovery" }
        let(:code) { recovery_codes.first }
        let(:form) { RecoveryCodeForm.from_params(code:, method_name:) }

        it "broadcasts ok with the user and consumes the recovery code" do
          expect { subject.call }.to broadcast(:ok, user)
          expect(RecoveryCode.redeem!(user, code)).to be(false)
        end
      end

      context "when the method name is unknown" do
        let(:method_name) { "carrier_pigeon" }

        it "broadcasts invalid" do
          expect { subject.call }.to broadcast(:invalid)
        end
      end

      context "when the wrong codes exhaust the attempts" do
        let(:code) { "000000" }
        let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
        let(:other_challenge) { create(:two_factor_challenge, user:) }

        before do
          allow(Rails).to receive(:cache).and_return(memory_store)
          (Decidim.two_factor_max_attempts - 1).times { described_class.call(challenge, form) }
        end

        it "broadcasts exhausted and alerts the account owner" do
          expect { subject.call }.to broadcast(:exhausted).and(have_enqueued_job(ActionMailer::MailDeliveryJob).with("Decidim::TwoFactorMailer", "attempts_exhausted", "deliver_now", { args: [user] }))
        end

        it "does not alert the account owner again within the interval" do
          subject.call
          clear_enqueued_jobs

          Decidim.two_factor_max_attempts.times { described_class.call(other_challenge, form) }

          expect(ActionMailer::MailDeliveryJob).not_to have_been_enqueued
        end

        it "alerts the account owner again once the interval is over" do
          subject.call
          clear_enqueued_jobs

          travel(Decidim.two_factor_alert_interval + 1.minute) { Decidim.two_factor_max_attempts.times { described_class.call(other_challenge, form) } }

          expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.once
        end
      end

      context "when a concurrent request has taken the last attempt" do
        before { Challenge.find(challenge.id).update!(attempts_count: Decidim.two_factor_max_attempts) }

        it "broadcasts exhausted even with the right code and does not consume the challenge" do
          expect { subject.call }.to broadcast(:exhausted)
          expect(challenge.reload.consumed_at).to be_nil
        end
      end

      context "when the challenge is already consumed" do
        before { challenge.consume! }

        it "broadcasts expired" do
          expect { subject.call }.to broadcast(:expired)
        end
      end
    end
  end
end
