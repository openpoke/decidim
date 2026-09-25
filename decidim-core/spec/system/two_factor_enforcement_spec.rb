# frozen_string_literal: true

require "spec_helper"

describe "Two-factor enforcement" do
  let(:organization) { create(:organization, :with_two_factor_enforced_for_admins, two_factor_enforced_at:) }
  let(:user) { create(:user, :admin, :confirmed, organization:, created_at: 30.days.ago) }
  let(:two_factor_enforced_at) { 20.days.ago }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  context "when the grace period is over" do
    it "forces the admin area too" do
      visit decidim_admin.root_path

      expect(page).to have_current_path(decidim.two_factor_authentication_path)
    end

    it "sends the user back where they came from after the setup" do
      visit decidim.notifications_settings_path

      expect(page).to have_current_path(decidim.two_factor_authentication_path)
      expect(page).to have_text("Set it up to continue")

      click_on "Authenticator app"
      secret = Decidim::TwoFactor::TotpAuthenticator.find_by(user:).secret
      fill_in "Enter the 6-digit code the app shows", with: totp_code_for(secret)
      click_on "Confirm"
      click_on "I have saved the codes"

      expect(page).to have_current_path(decidim.notifications_settings_path)
    end
  end

  context "when the grace period is running" do
    let(:two_factor_enforced_at) { Time.current }

    it "shows the banner and lets the user postpone it for the session" do
      visit decidim.account_path

      expect(page).to have_current_path(decidim.account_path)

      within "#two-factor-setup-message-container" do
        expect(page).to have_text("requires two-factor authentication")
        click_on "Remind me later"
      end

      expect(page).to have_current_path(decidim.account_path)
      expect(page).to have_no_css("#two-factor-setup-message-container")

      visit decidim.account_path

      expect(page).to have_no_css("#two-factor-setup-message-container")
    end

    it "does not show the banner on the setup page itself" do
      visit decidim.two_factor_authentication_path

      expect(page).to have_no_css("#two-factor-setup-message-container")
      expect(page).to have_text("You can postpone the setup until")
    end
  end
end
