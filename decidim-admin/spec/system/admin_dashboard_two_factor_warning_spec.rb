# frozen_string_literal: true

require "spec_helper"

describe "Admin dashboard two-factor warning" do
  let(:organization) { create(:organization, :with_two_factor_enforced_for_admins, two_factor_grace_period_days: 7) }
  let(:user) { create(:user, :admin, :confirmed, organization:) }

  before do
    switch_to_host(organization.host)
    login_past_second_factor(user)
  end

  it "warns the admin who has not set up a second factor yet" do
    visit decidim_admin.root_path

    expect(page).to have_text("Your organization requires two-factor authentication")
    expect(page).to have_link("Set it up")
  end

  context "when two-factor authentication is not enforced" do
    let(:organization) { create(:organization, :with_two_factor_authentication_enabled) }

    it "shows no warning" do
      visit decidim_admin.root_path

      expect(page).to have_no_text("Your organization requires two-factor authentication")
    end
  end
end
