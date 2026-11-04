# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TwoFactor
    describe Challenge do
      let(:user) { create(:user, :confirmed) }
      let(:challenge) { create(:two_factor_challenge, user:) }

      describe "#active?" do
        it "expires after the TTL" do
          expect(challenge).to be_active
          travel Decidim.two_factor_code_expiry_time + 1.minute do
            expect(challenge).to be_expired
            expect(challenge).not_to be_active
          end
        end
      end

      describe "#consume!" do
        it "consumes the challenge only once and stops it being active" do
          expect(challenge.consume!).to be(true)
          expect(challenge).not_to be_active
          expect(described_class.find(challenge.id).consume!).to be(false)
        end
      end

      describe "#register_attempt!" do
        it "stops the challenge being active after the attempt limit and refuses further attempts" do
          Decidim.two_factor_max_attempts.times { expect(challenge.register_attempt!).to be(true) }
          expect(challenge).not_to be_active
          expect(described_class.exhausted).to include(challenge)
          expect(challenge.register_attempt!).to be(false)
          expect(challenge.reload.attempts_count).to eq(Decidim.two_factor_max_attempts)
        end

        it "refuses the attempt once consumed" do
          challenge.consume!
          expect(challenge.register_attempt!).to be(false)
          expect(challenge.reload.attempts_count).to eq(0)
        end
      end

      describe ".issue_for" do
        let!(:challenge) { described_class.issue_for(user, purpose: "login") }

        it "reuses the pending challenge of the same purpose" do
          expect(described_class.issue_for(user, purpose: "login")).to eq(challenge)
          expect(described_class.issue_for(user, purpose: "confirmation")).not_to eq(challenge)
        end

        it "issues a new one once the pending challenge is consumed or expired" do
          travel(Decidim.two_factor_code_expiry_time + 1.minute) { expect(described_class.issue_for(user, purpose: "login")).not_to eq(challenge) }

          challenge.consume!

          expect(described_class.issue_for(user, purpose: "login")).not_to eq(challenge)
        end

        it "issues a new one once the password changed" do
          user.update!(password: "another-password-123456")

          expect(described_class.issue_for(user, purpose: "login")).not_to eq(challenge)
        end
      end

      describe "#valid_code?" do
        let(:challenge) { create(:two_factor_challenge, user:, method_type: "email") }

        before { challenge.update!(code: "123456") }

        it "validates the right code, rejects others and stores only the digest" do
          expect(challenge.code_digest).not_to eq("123456")
          expect(challenge.valid_code?("123456")).to be(true)
          expect(challenge.valid_code?(" 123456 ")).to be(true)
          expect(challenge.valid_code?("654321")).to be(false)
          expect(challenge.valid_code?(nil)).to be(false)
          expect(create(:two_factor_challenge, user:).valid_code?("123456")).to be(false)
        end
      end
    end
  end
end
