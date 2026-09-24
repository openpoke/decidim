# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TwoFactor
    describe EnforcementPolicy do
      subject { described_class.new(user) }

      let(:organization) { create(:organization, :with_two_factor_authentication_enabled) }
      let(:user) { create(:user, :confirmed, organization:) }

      context "when nothing is enforced" do
        it "does not ask anyone to set up a factor" do
          expect(subject.setup_pending?).to be(false)
          expect(subject.setup_required?).to be(false)
        end

        it "challenges only the users holding a confirmed factor" do
          expect(subject.challenge_required?).to be(false)

          create(:totp_authenticator, :confirmed, user:)

          expect(subject.challenge_required?).to be(true)
        end
      end

      context "when enforced for admins" do
        let(:organization) { create(:organization, :with_two_factor_enforced_for_admins) }
        let(:user) { create(:user, :admin, :confirmed, organization:) }

        it "asks an admin without a factor to set one up" do
          expect(subject.setup_pending?).to be(true)
          expect(subject.setup_required?).to be(false)
        end

        it "leaves participants alone" do
          participant = described_class.new(create(:user, :confirmed, organization:))

          expect(participant.setup_pending?).to be(false)
          expect(participant.setup_required?).to be(false)
        end

        it "does not ask an admin who already has a confirmed factor" do
          create(:totp_authenticator, :confirmed, user:)

          expect(subject.setup_pending?).to be(false)
          expect(subject.setup_required?).to be(false)
        end

        it "turns the pending setup into a required one once the window closes" do
          expect(subject.grace_ends_at).to be_within(1.minute).of(1.day.from_now)

          travel 2.days do
            expect(subject.setup_pending?).to be(false)
            expect(subject.setup_required?).to be(true)
          end
        end

        it "honors the organization's own grace period" do
          organization.update!(two_factor_grace_period_days: 10)

          expect(subject.grace_ends_at).to be_within(1.minute).of(10.days.from_now)
        end

        it "gives no grace when the organization disables the grace period" do
          organization.update!(two_factor_grace_period_days: 0)

          expect(subject.setup_pending?).to be(false)
          expect(subject.setup_required?).to be(true)
        end

        it "grants users who signed up after the switch the full window from their sign-up" do
          organization.update!(two_factor_enforced_at: 30.days.ago)

          expect(subject.grace_ends_at).to be_within(1.minute).of(1.day.from_now)
        end
      end

      context "when enforced for everyone" do
        let(:organization) { create(:organization, :with_two_factor_enforced_for_all) }

        it "asks participants too" do
          expect(subject.setup_pending?).to be(true)
        end

        it "leaves ephemeral and managed users alone" do
          expect(described_class.new(create(:user, :ephemeral, organization:)).setup_pending?).to be(false)
          expect(described_class.new(create(:user, :managed, organization:)).setup_pending?).to be(false)
        end
      end

      context "when the organization has two-factor authentication disabled" do
        let(:organization) { create(:organization, :with_two_factor_enforced_for_all, two_factor_authentication_enabled: false) }

        it "leaves everyone alone" do
          create(:totp_authenticator, :confirmed, user:)

          expect(subject.challenge_required?).to be(false)
          expect(subject.setup_pending?).to be(false)
          expect(subject.setup_required?).to be(false)
        end
      end
    end
  end
end
