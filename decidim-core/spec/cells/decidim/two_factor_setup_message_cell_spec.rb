# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe TwoFactorSetupMessageCell, type: :cell do
    controller Decidim::ApplicationController

    subject { cell("decidim/two_factor_setup_message", user).call }

    let(:organization) { create(:organization, :with_two_factor_enforced_for_all) }
    let(:user) { create(:user, :confirmed, organization:) }

    it "invites the user to set up the second factor before the deadline" do
      expect(subject).to have_css("#two-factor-setup-message-container")
      expect(subject).to have_text("Your organization requires two-factor authentication")
      expect(subject).to have_text("before #{I18n.l(user.two_factor_grace_ends_at.to_date, format: :decidim_short)}")
      expect(subject).to have_link("Set it up", href: "/en/two_factor_authentication")
      expect(subject).to have_button("Remind me later")
    end

    context "when the user is not affected by the enforcement" do
      let(:organization) { create(:organization, :with_two_factor_enforced_for_admins) }

      it "renders nothing" do
        expect(subject.text).to be_blank
      end
    end

    context "when the session came through a provider bypassing the second factor" do
      before { controller.session["decidim_two_factor_bypassed"] = user.id }

      it "renders nothing" do
        expect(subject.text).to be_blank
      end
    end

    context "when the bypass belongs to another account" do
      before { controller.session["decidim_two_factor_bypassed"] = user.id + 1 }

      it "still invites the user" do
        expect(subject).to have_css("#two-factor-setup-message-container")
      end
    end
  end
end
