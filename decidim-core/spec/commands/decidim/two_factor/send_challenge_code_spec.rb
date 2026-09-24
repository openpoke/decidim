# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TwoFactor
    describe SendChallengeCode do
      subject { described_class.new(challenge) }

      let(:user) { create(:user, :confirmed) }
      let!(:email_method) { create(:email_authenticator, user:) }
      let(:challenge) { create(:two_factor_challenge, user:) }

      before { stub_email_code }

      context "when everything is ok" do
        it "switches the challenge to the email method and mails a code matching the stored digest" do
          expect { subject.call }.to broadcast(:ok)
          expect(challenge.reload.method_type).to eq("email")
          expect(challenge.valid_code?("123456")).to be(true)
          expect(last_email.to).to eq([user.email])
          expect(last_email.body.encoded).to include("123456")
        end
      end

      context "when a code was sent a moment ago" do
        before do
          described_class.call(challenge)
          clear_emails
        end

        it "broadcasts throttled until the interval passes" do
          expect { subject.call }.to broadcast(:throttled)
          expect(emails).to be_empty

          travel Decidim.two_factor_resend_interval + 1.second do
            expect { subject.call }.to broadcast(:ok)
          end
        end
      end

      context "when the challenge is already consumed" do
        before { challenge.consume! }

        it "broadcasts invalid" do
          expect { subject.call }.to broadcast(:invalid)
        end
      end

      context "when the account has no email method attached" do
        let(:challenge) { create(:two_factor_challenge) }

        it "broadcasts invalid without mailing anything" do
          expect { subject.call }.to broadcast(:invalid)
          expect(emails).to be_empty
        end
      end
    end
  end
end
