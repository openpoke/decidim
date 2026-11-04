# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TwoFactor
    describe ResetUser do
      subject { described_class.new(user) }

      let(:user) { create(:user, :confirmed) }

      context "when the account has second factors" do
        let(:user) { create(:user, :confirmed, :with_recovery_codes) }
        let!(:authenticator) { create(:totp_authenticator, :confirmed, user:) }
        let!(:challenge) { create(:two_factor_challenge, user:) }

        it "removes the factors, the codes and the challenges, and alerts the account owner" do
          expect { subject.call }.to broadcast(:ok).and(have_enqueued_job(ActionMailer::MailDeliveryJob).with("Decidim::TwoFactorMailer", "factors_reset", "deliver_now", args: [user]))

          expect(Authenticator.where(user:)).to be_empty
          expect(RecoveryCode.where(user:)).to be_empty
          expect(Challenge.where(user:)).to be_empty
        end
      end

      context "when the account has no second factor" do
        it "broadcasts invalid" do
          expect { subject.call }.to broadcast(:invalid)
        end
      end
    end
  end
end
