# frozen_string_literal: true

require "spec_helper"

describe "Two-factor with omniauth sign in" do
  include_context "with a two-factor request session"

  let(:user) { create(:user, :confirmed, organization:, email: "user@from-facebook.com") }
  let!(:identity) { create(:identity, user:, provider: "facebook", uid: "12345") }
  let(:omniauth_hash) { OmniAuth::AuthHash.new(provider: "facebook", uid: "12345", info: { email: user.email, name: "Facebook User", nickname: "facebook_user" }) }
  let(:omniauth_secrets) { { facebook: { enabled: true, app_id: "fake-facebook-app-id", app_secret: "fake-facebook-app-secret", icon: "phone" } } }

  before do
    allow(Decidim).to receive(:omniauth_providers).and_return(omniauth_secrets)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:facebook] = omniauth_hash
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:facebook] = nil
  end

  def sign_in_with_facebook
    get("/users/auth/facebook/callback", headers:)
  end

  context "when the user has an authenticator app attached" do
    include_context "with a user holding an authenticator app"

    it "interrupts the omniauth login until the code is entered" do
      sign_in_with_facebook

      expect(response).to redirect_to(routes.user_two_factor_challenge_path(locale: "en"))
      expect(account_status).to eq(302)
    end
  end

  context "when facebook is configured to bypass the second factor" do
    let(:omniauth_secrets) { { facebook: { enabled: true, app_id: "fake-facebook-app-id", app_secret: "fake-facebook-app-secret", icon: "phone", bypass_two_factor: true } } }

    context "with an authenticator app attached" do
      include_context "with a user holding an authenticator app"

      it "lets the user in without a challenge" do
        sign_in_with_facebook

        expect(account_status).to eq(200)
      end
    end

    context "with the organization enforcing two-factor for everyone" do
      let(:organization) { create(:organization, :with_two_factor_enforced_for_all, two_factor_enforced_at: 20.days.ago) }
      let(:user) { create(:user, :confirmed, organization:, email: "user@from-facebook.com", created_at: 30.days.ago) }

      it "does not send the session to the setup" do
        sign_in_with_facebook

        expect(account_status).to eq(200)
      end

      it "does not carry the bypass over to the next account signing in" do
        other = create(:user, :confirmed, organization:, created_at: 30.days.ago)

        sign_in_with_facebook
        delete(routes.destroy_user_session_path(locale: "en"), headers:)
        post(routes.user_session_path(locale: "en"), params: { user: { email: other.email, password: } }, headers:)

        expect(account_status).to eq(302)
        expect(response).to redirect_to(routes.two_factor_authentication_path(locale: "en"))
      end
    end
  end

  context "when the organization itself marks facebook as bypassing the second factor" do
    let(:organization) { create(:organization, :with_two_factor_authentication_enabled, omniauth_settings:) }
    let(:omniauth_settings) { { "omniauth_settings_facebook_enabled" => true, "omniauth_settings_facebook_bypass_two_factor" => true } }

    include_context "with a user holding an authenticator app"

    it "lets the user in without a challenge" do
      sign_in_with_facebook

      expect(account_status).to eq(200)
    end
  end
end
