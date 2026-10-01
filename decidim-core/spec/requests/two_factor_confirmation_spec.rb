# frozen_string_literal: true

require "spec_helper"

describe "Two-factor confirmation" do
  include_context "with a two-factor request session"
  include_context "with a user holding an authenticator app"

  let(:confirmation_path) { routes.two_factor_authentication_confirmation_path(locale: "en") }
  let(:removal_path) { routes.two_factor_authentication_authenticator_path(authenticator, locale: "en") }

  before { login_past_second_factor(user) }

  def confirm_with_password
    post(confirmation_path, params: { password: }, headers:)
  end

  shared_examples "an open confirmation window" do
    it "lets the guarded action through" do
      expect(response).to redirect_to(routes.two_factor_authentication_path(locale: "en"))

      delete(removal_path, headers:)

      expect(Decidim::TwoFactor::Authenticator.where(user:)).to be_empty
    end
  end

  describe "the gate" do
    it "refuses non-HTML requests without offering the screen" do
      delete(routes.two_factor_authentication_authenticator_path(authenticator, locale: "en", format: :json), headers:)

      expect(response).to have_http_status(:forbidden)
      expect(authenticator.reload).to be_persisted
    end

    it "shows the screen with the form of the interrupted action" do
      delete(removal_path, headers:)

      expect(response).to redirect_to(confirmation_path)

      get(confirmation_path, headers:)

      expect(response.body).to include(%(action="#{removal_path}"))
      expect(response.body).to include('name="_method" value="delete"')
    end

    it "forgets the interrupted action once it expires" do
      delete(removal_path, headers:)

      travel(Decidim.two_factor_code_expiry_time + 1.minute) do
        get(confirmation_path, headers:)

        expect(response.body).to include(%(action="#{confirmation_path}"))
        expect(response.body).not_to include(%(action="#{removal_path}"))
      end
    end

    context "when the user has no factor yet" do
      before { login_past_second_factor(create(:user, :confirmed, organization:)) }

      it "redirects the confirmation screen away" do
        get(confirmation_path, headers:)

        expect(response).to redirect_to(routes.two_factor_authentication_path(locale: "en"))
      end
    end
  end

  describe "confirming the interrupted action" do
    it "removes the factor once the password is sent along" do
      delete(removal_path, headers:)

      expect(response).to redirect_to(confirmation_path)

      delete(removal_path, params: { password: }, headers:)

      expect(response).to redirect_to(routes.two_factor_authentication_path(locale: "en"))
      expect(Decidim::TwoFactor::Authenticator.where(user:)).to be_empty
    end

    it "resumes an interrupted get action with a plain redirect" do
      get(routes.new_two_factor_authentication_totp_authenticator_path(locale: "en"), headers:)
      confirm_with_password

      expect(response).to redirect_to(routes.new_two_factor_authentication_totp_authenticator_path(locale: "en"))
    end

    it "sends a wrong password back to the screen and counts the attempt" do
      delete(removal_path, params: { password: "wrong" }, headers:)

      expect(response).to redirect_to(confirmation_path)
      expect(flash[:alert]).to be_present
      expect(authenticator.reload).to be_persisted
      expect(Decidim::TwoFactor::Challenge.find_by(user:, purpose: "confirmation").attempts_count).to eq(1)
    end
  end

  describe "confirming with the password" do
    context "when the password is right" do
      before { confirm_with_password }

      it_behaves_like "an open confirmation window"
    end

    it "locks the confirmation once the attempts are exhausted" do
      get(confirmation_path, headers:)
      Decidim.two_factor_max_attempts.times { post(confirmation_path, params: { password: "wrong" }, headers:) }

      confirm_with_password

      expect(response).to redirect_to(routes.two_factor_authentication_path(locale: "en"))

      delete(removal_path, headers:)

      expect(authenticator.reload).to be_persisted
    end

    it "asks again once the window is over" do
      confirm_with_password

      travel(Decidim.two_factor_confirmation_window + 1.minute) do
        delete(removal_path, headers:)

        expect(response).to redirect_to(confirmation_path)
        expect(authenticator.reload).to be_persisted
      end
    end

    context "when the organization has no password sign-in" do
      let(:organization) { create(:organization, :with_two_factor_authentication_enabled, users_registration_mode: :disabled) }

      it "does not offer nor accept the password" do
        get(confirmation_path, headers:)

        expect(response.body).not_to include('name="password[password]"')

        confirm_with_password

        expect(response).to redirect_to(confirmation_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "confirming with a code" do
    def confirm_with_code(code)
      post(confirmation_path, params: { method_name: "totp", code: }, headers:)
    end

    context "when the code is right" do
      before do
        get(confirmation_path, headers:)
        confirm_with_code(totp_code_for(secret))
      end

      it_behaves_like "an open confirmation window"
    end

    it "rejects a wrong code" do
      get(confirmation_path, headers:)
      confirm_with_code("000000")

      expect(response).to redirect_to(confirmation_path)
      expect(flash[:alert]).to be_present
    end

    it "locks the confirmation once the wrong codes exhaust the attempts" do
      get(confirmation_path, headers:)
      Decidim.two_factor_max_attempts.times { confirm_with_code("000000") }

      expect(response).to redirect_to(routes.two_factor_authentication_path(locale: "en"))
      expect(flash[:alert]).to eq(I18n.t("decidim.two_factor_confirmations.show.exhausted"))
    end

    it "refuses to mail a code to an account without the email method" do
      get(confirmation_path, headers:)
      post(routes.send_code_two_factor_authentication_confirmation_path(locale: "en"), headers:)

      expect(response).to redirect_to(confirmation_path)
      expect(flash[:alert]).to eq(I18n.t("decidim.two_factor_confirmations.show.expired"))
    end
  end

  it_behaves_like "a two-factor page hidden without two-factor authentication" do
    let(:path) { confirmation_path }
  end
end
