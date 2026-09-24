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
end
