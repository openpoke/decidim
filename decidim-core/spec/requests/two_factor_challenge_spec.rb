# frozen_string_literal: true

require "spec_helper"

describe "Two-factor challenge" do
  include_context "with a two-factor request session"
  include_context "with a user holding an authenticator app"

  def answer_challenge(code = totp_code_for(secret), method_name: "totp")
    post(routes.user_two_factor_challenge_path(locale: "en"), params: { method_name:, code: }, headers:)
  end

  it "interrupts the password login until the code is entered" do
    sign_in_with_password

    expect(response).to redirect_to(routes.user_two_factor_challenge_path(locale: "en"))
    expect(account_status).to eq(302)
  end

  it "restarts the login when the password changed meanwhile" do
    sign_in_with_password
    user.update!(password: "another-password-123456")
    answer_challenge

    expect(response).to redirect_to(routes.new_user_session_path(locale: "en"))
    expect(account_status).to eq(302)
  end

  it "rejects a wrong code and keeps the session logged out" do
    sign_in_with_password
    answer_challenge("000000")

    expect(response).to have_http_status(:unprocessable_content)
    expect(account_status).to eq(302)
  end

  it "mails an email code on demand and accepts it" do
    stub_email_code
    create(:email_authenticator, user:)

    sign_in_with_password
    post(routes.send_code_user_two_factor_challenge_path(locale: "en"), headers:)

    expect(flash[:notice]).to eq(I18n.t("decidim.two_factor.challenge.code_sent"))
    expect(last_email.to).to eq([user.email])

    answer_challenge("123456", method_name: "email")

    expect(account_status).to eq(200)
  end

  it "refuses to mail a code to an account without the email method" do
    sign_in_with_password
    post(routes.send_code_user_two_factor_challenge_path(locale: "en"), headers:)

    expect(response).to redirect_to(routes.new_user_session_path(locale: "en"))
    expect(account_status).to eq(302)
  end

  it "throttles a second code asked right after the first" do
    create(:email_authenticator, user:)

    sign_in_with_password
    post(routes.send_code_user_two_factor_challenge_path(locale: "en"), headers:)
    post(routes.send_code_user_two_factor_challenge_path(locale: "en"), headers:)

    expect(flash[:alert]).to eq(I18n.t("decidim.two_factor.challenge.code_throttled"))
  end

  it "restarts the login once the attempts run out" do
    sign_in_with_password
    Decidim.two_factor_max_attempts.times { answer_challenge("000000") }

    expect(response).to redirect_to(routes.new_user_session_path(locale: "en"))
  end

  it "returns to the home page instead of the consumed confirmation link once the code is entered" do
    user.update!(email: "changed@example.org")
    get(routes.user_confirmation_path(locale: "en", confirmation_token: user.reload.confirmation_token), headers:)

    expect(response).to redirect_to(routes.user_two_factor_challenge_path(locale: "en"))

    answer_challenge

    expect(response).to redirect_to(routes.root_path(locale: "en"))
    expect(account_status).to eq(200)
  end

  it "returns to the page requested before the login once the code is entered" do
    post(routes.user_session_path(locale: "en"), params: { user: { email: user.email, password: }, redirect_url: routes.account_path(locale: "en") }, headers:)
    get(URI.parse(response.location).request_uri, headers:)
    answer_challenge

    expect(response).to redirect_to(routes.account_path(locale: "en"))
  end

  it "redirects to the login when there is no pending challenge" do
    get(routes.user_two_factor_challenge_path(locale: "en"), headers:)

    expect(response).to redirect_to(routes.new_user_session_path(locale: "en"))
  end

  context "when the email code is the only method" do
    let!(:authenticator) { create(:email_authenticator, user:) }

    it "mails the code when the screen opens" do
      sign_in_with_password
      get(routes.user_two_factor_challenge_path(locale: "en"), headers:)

      expect(last_email.to).to eq([user.email])
    end
  end

  context "when an admin signs in with a weak password" do
    let(:password) { "decidim123" }
    let(:user) { create(:user, :confirmed, organization:, password:) }

    before do
      user.password = nil
      user.update!(admin: true)
    end

    it "asks for a new password once the code is entered" do
      sign_in_with_password
      answer_challenge

      expect(user.reload.password_updated_at).to be_nil
      expect(response).to redirect_to(routes.change_password_path(locale: "en"))
    end
  end

  describe "signing in through a password reset" do
    let(:new_password) { "DfyvHn425mYAy2HL" }

    it "changes the password and asks for the code before the session starts" do
      token = user.send_reset_password_instructions
      put(routes.user_password_path(locale: "en"), params: { user: { reset_password_token: token, password: new_password } }, headers:)

      expect(response).to redirect_to(routes.user_two_factor_challenge_path(locale: "en"))
      expect(user.reload.valid_password?(new_password)).to be(true)
      expect(account_status).to eq(302)
    end
  end

  describe "remember me" do
    it "sets the cookie once the code is entered and asks for the code again on a new session" do
      post(routes.user_session_path(locale: "en"), params: { user: { email: user.email, password:, remember_me: "1" } }, headers:)

      expect(response.cookies["remember_user_token"]).to be_blank

      answer_challenge
      remember_token = response.cookies["remember_user_token"]

      expect(remember_token).to be_present

      reset!
      cookies["remember_user_token"] = remember_token
      get(routes.account_path(locale: "en"), headers:)

      expect(response).to redirect_to(routes.user_two_factor_challenge_path(locale: "en"))

      get(routes.user_two_factor_challenge_path(locale: "en"), headers:)

      expect(response).to have_http_status(:ok)

      travel(31.seconds) { answer_challenge }

      expect(account_status).to eq(200)
    end

    it "keeps the other remembered devices when a password attempt is interrupted" do
      user.remember_me!
      sign_in_with_password

      expect(user.reload.remember_created_at).to be_present
    end
  end
end
