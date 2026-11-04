# frozen_string_literal: true

require "spec_helper"

describe "Passkey sign in" do
  include_context "with a two-factor request session"
  include_context "with a fake passkey client"

  let!(:authenticator) { enroll_fake_passkey(user, fake_client, relying_party) }
  let(:user_handle) { Base64.urlsafe_decode64(authenticator.metadata["user_handle"]) }

  def passkey_credential(user_verified: true, user_handle: self.user_handle)
    get(routes.new_user_session_path(locale: "en"), headers:)
    options = JSON.parse(Nokogiri::HTML(response.body).at("[data-passkey-options-value]")["data-passkey-options-value"])
    fake_client.get(challenge: options["challenge"], user_verified:, user_handle:).to_json
  end

  def sign_in_with_passkey(credential = passkey_credential)
    post(routes.user_passkey_session_path(locale: "en"), params: { credential: }, headers:)
  end

  it "signs the user in without a password or a second step" do
    sign_in_with_passkey

    expect(account_status).to eq(200)
    expect(authenticator.reload.last_used_at).to be_present
  end

  shared_examples "a refused passkey sign in" do
    it "sends the user back to the login form" do
      expect(response).to redirect_to(routes.new_user_session_path(locale: "en"))
      expect(flash[:alert]).to eq(I18n.t("decidim.devise.passkey_sessions.create.invalid"))
      expect(account_status).to eq(302)
    end
  end

  context "when the device did not verify the user" do
    before { sign_in_with_passkey(passkey_credential(user_verified: false)) }

    it_behaves_like "a refused passkey sign in"
  end

  context "when the passkey names another user" do
    before { sign_in_with_passkey(passkey_credential(user_handle: "someone else")) }

    it_behaves_like "a refused passkey sign in"
  end

  context "when the same sign in is replayed" do
    before do
      credential = passkey_credential
      sign_in_with_passkey(credential)
      delete(routes.destroy_user_session_path(locale: "en"), headers:)
      sign_in_with_passkey(credential)
    end

    it_behaves_like "a refused passkey sign in"
  end

  context "when the organization does not offer passkeys" do
    before { organization.update!(available_two_factor_methods: %w(totp)) }

    it "is not reachable" do
      get(routes.new_user_session_path(locale: "en"), headers:)
      expect(response.body).not_to include("data-passkey-options-value")

      post(routes.user_passkey_session_path(locale: "en"), params: { credential: "{}" }, headers:)
      expect(response).to have_http_status(:not_found)
    end
  end
end
