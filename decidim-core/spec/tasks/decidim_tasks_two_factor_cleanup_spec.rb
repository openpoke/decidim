# frozen_string_literal: true

require "spec_helper"

describe "rake decidim:two_factor:cleanup", type: :task do
  let(:user) { create(:user, :confirmed) }
  let!(:pending_challenge) { create(:two_factor_challenge, user:) }
  let!(:consumed) { create(:two_factor_challenge, user:, consumed_at: 1.minute.ago) }
  let!(:expired) { create(:two_factor_challenge, user:, expires_at: 1.minute.ago) }

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "deletes the consumed and expired challenges" do
    task.execute

    expect(Decidim::TwoFactor::Challenge.all).to contain_exactly(pending_challenge)
    expect($stdout.string).to include("Deleted 2 second-factor challenges")
  end
end
