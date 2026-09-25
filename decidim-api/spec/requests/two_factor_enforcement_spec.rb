# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Api two-factor enforcement" do
  let(:organization) { create(:organization, :with_two_factor_enforced_for_all, two_factor_enforced_at: 20.days.ago) }
  let(:user) { create(:user, :confirmed, organization:, created_at: 30.days.ago) }
  let(:query) { "{session { user { id nickname } } }" }
  let(:headers) { { "ACCEPT" => "application/json" } }

  before { host! organization.host }

  context "when the participant is signed in with the browser session" do
    before { login_as user, scope: :user }

    it "refuses the session until the second factor is set up" do
      post("/api", params: { query: }, headers:)

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when a participant with a second factor calls with an OAuth token" do
    let(:application) { create(:oauth_application, organization:) }
    let(:scopes) { Doorkeeper::OAuth::Scopes.from_string("user api:read") }
    let(:token) { Decidim::OAuth::TokenGenerator.generate(application:, resource_owner_id: user.id, scopes:) }

    before do
      create(:totp_authenticator, :confirmed, user:)
      create(:oauth_access_token, application:, resource_owner_id: user.id, scopes: scopes.to_s, token:)
    end

    it "answers without asking for the second factor" do
      post("/api", params: { query: }, headers: headers.merge("Authorization" => "Bearer #{token}", "X-JWT-AUD" => application.uid))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "session", "user", "id")).to eq(user.id.to_s)
    end
  end
end
