# frozen_string_literal: true

require "spec_helper"

describe "Two-factor confirmation" do
  include_context "with a two-factor organization"

  let(:user) { create(:user, :confirmed, :with_recovery_codes, organization:) }
  let!(:authenticator) { create(:totp_authenticator, :confirmed, user:) }

  before do
    switch_to_host(organization.host)
    login_past_second_factor(user)
    visit decidim.two_factor_authentication_path
  end

  it "asks for confirmation before enabling a second factor and resumes the action" do
    click_on "Email code"

    expect(page).to have_text("Confirm enabling the email code")

    fill_in "Password", with: password
    click_on "Confirm with the password"

    expect(page).to have_text("The email code was enabled for your account.")
    expect(Decidim::TwoFactor::EmailAuthenticator.where(user:)).to be_present
  end
end
