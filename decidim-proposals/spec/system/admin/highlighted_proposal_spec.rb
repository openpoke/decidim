# frozen_string_literal: true

require "spec_helper"

describe "Highlighted proposal", type: :system do
  let(:admin) { create :user, :admin, :confirmed }
  let(:organization) { admin.organization }
  let!(:participatory_process) { create(:participatory_process, organization: organization) }
  let!(:proposal_component) { create(:proposal_component, participatory_space: participatory_process) }
  let!(:proposals) do
    [
      create(:proposal, :not_answered, created_at: 10.days.ago, published_at: 10.days.ago, component:
        proposal_component),
      create(:proposal, :evaluating, created_at: 10.days.ago, published_at: 10.days.ago, component:
        proposal_component),
      create(:proposal, :accepted, created_at: 10.days.ago, published_at: 10.days.ago, component:
        proposal_component)
    ]
  end

  before do
    switch_to_host(organization.host)
    allow(Decidim::Proposals.config).to receive(:unanswered_proposals_overdue).and_return unanswered_days_overdue.to_i
    allow(Decidim::Proposals.config).to receive(:evaluating_proposals_overdue).and_return evaluating_days_overdue.to_i
    login_as admin, scope: :user
    visit decidim_admin.root_path
    click_link "Processes"

    within "#processes" do
      click_link translated(participatory_process.title)
    end

    click_link "Components"

    within "#components-list" do
      click_link "Proposals"
    end
  end

  context "when overdue days is larger" do
    let(:unanswered_days_overdue) { 12 }
    let(:evaluating_days_overdue) { 2 }

    it "proposals with :not_answered and :evaluating hava a grace period" do
      expect(page).not_to have_css(".help-text-overdue.text-alert")
      expect(page).to have_css(".help-text-overdue.text-warning", count: 2)
    end
  end

  context "when overdue days is shorter" do
    let(:unanswered_days_overdue) { 5 }
    let(:evaluating_days_overdue) { 2 }

    it "all :not_answered and :evaluating proposals have help text with class .text-alert" do
      expect(page).to have_css(".help-text-overdue.text-alert", count: 2)
      expect(page).not_to have_css(".help-text-overdue", count: 1)
    end
  end

  context "when proposal has grace period evaluating" do
    let(:unanswered_days_overdue) { 5 }
    let(:evaluating_days_overdue) { 7 }

    it "proposal has help text with class .text-warning" do
      expect(page).to have_css(".help-text-overdue.text-warning", count: 1)
    end
  end

  context "when overdue days is zero" do
    let(:unanswered_days_overdue) { 0 }
    let(:evaluating_days_overdue) { 0 }

    it "proposals are not highlighted" do
      expect(page).not_to have_css(".help-text-overdue")
    end
  end
end
