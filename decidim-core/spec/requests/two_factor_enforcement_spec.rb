# frozen_string_literal: true

require "spec_helper"

describe "Two-factor enforcement" do
  include_context "with a two-factor request session"

  let(:organization) { create(:organization, :with_two_factor_enforced_for_all, two_factor_enforced_at: 20.days.ago) }
  let(:user) { create(:user, :confirmed, organization:, created_at: 30.days.ago) }

  context "when the participant is signed in" do
    before { login_as user, scope: :user }

    it "redirects HTML requests to the setup page" do
      expect(account_status).to eq(302)
      expect(response).to redirect_to(routes.two_factor_authentication_path(locale: "en"))
    end

    it "lets background requests through, as the other walls do" do
      get(routes.seconds_until_timeout_path(format: :json), headers:)

      expect(response).to have_http_status(:ok)
    end

    it "still serves the allowed paths" do
      get(routes.delete_account_path(locale: "en"), headers:)

      expect(response).to have_http_status(:ok)

      get(routes.download_download_your_data_path(locale: "en", uuid: "missing"), headers:)

      expect(response).to redirect_to(routes.download_your_data_path(locale: "en"))

      post(routes.locale_path, params: { locale: "ca" }, headers:)

      expect(response).to have_http_status(:redirect)
      expect(response).not_to redirect_to(routes.two_factor_authentication_path(locale: "en"))

      get(routes.manifest_path(format: "webmanifest"), headers:)

      expect(response).to have_http_status(:ok)
    end

    it "lets the user delete the account" do
      delete(routes.account_path(locale: "en"), headers:)

      expect(response).to redirect_to(routes.root_path(locale: "en"))
      expect(user.reload).to be_deleted
    end
  end

  context "when an admin impersonates a participant" do
    let(:admin) { create(:user, :admin, :confirmed, organization:, created_at: 30.days.ago) }
    let!(:authenticator) { create(:totp_authenticator, :confirmed, user: admin) }
    let!(:impersonation_log) { create(:impersonation_log, admin:, user:) }

    before { login_past_second_factor(admin) }

    it "serves the impersonated session without the setup redirect" do
      expect(account_status).to eq(200)
    end

    it "hides the setup page from the impersonated session" do
      get(routes.two_factor_authentication_path(locale: "en"), headers:)

      expect(response).to redirect_to(routes.account_path(locale: "en"))
    end

    context "when the participant is still inside the grace period" do
      let(:user) { create(:user, :confirmed, organization:) }

      it "does not show the setup banner to the admin" do
        expect(account_status).to eq(200)
        expect(response.body).not_to include("two-factor-setup-message-container")
      end
    end
  end
end
