# frozen_string_literal: true

require "spec_helper"

describe "Two-factor challenge" do
  include_context "with a two-factor organization"
  include_context "with a user holding an authenticator app"

  before do
    switch_to_host(organization.host)
    visit decidim.new_user_session_path

    within ".new_user" do
      fill_in :session_user_email, with: user.email
      fill_in :session_user_password, with: password
      find("*[type=submit]").click
    end
  end

  it "asks for the code and logs the user in" do
    expect(page).to have_text("Enter the code")

    fill_in "Enter the 6-digit code the app shows", with: totp_code_for(secret)
    click_on "Confirm"

    expect(page).to have_text("Logged in successfully")
  end

  it "logs the user in with a recovery code" do
    codes = Decidim::TwoFactor::RegenerateRecoveryCodes.call(user)[:ok]

    click_on "Use a recovery code"
    fill_in "Enter one of your recovery codes", with: codes.first
    click_on "Confirm"

    expect(page).to have_text("Logged in successfully")
  end
end
