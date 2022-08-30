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
      create(:proposal, :evaluating, created_at: 10.days.ago, published_at: 10.days.ago, answered_at: 5.days.ago, component:
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

  context "when overdue days is zero" do
    let(:unanswered_days_overdue) { 0 }
    let(:evaluating_days_overdue) { 0 }

    it "proposals are not highlighted" do
      expect(page).not_to have_css(".help-text-overdue")
    end
  end

  context "when overdue days to answer are more" do
    let(:unanswered_days_overdue) { 12 }

    context "when proposal has a state of evaluation and evaluation is overdue" do
      let(:evaluating_days_overdue) { 2 }

      it "proposal with :not_answered has .text-alert" do
        expect(page).to have_css(".help-text-overdue.text-alert", count: 1)
      end

      it "proposal with :evaluating has .text-warning" do
        expect(page).to have_css(".help-text-overdue.text-warning", count: 1)
      end

      it "proposal with :accepted does not have .help-text-overdue" do
        expect(page).not_to have_css(".help-text-overdue", count: 1)
      end
    end

    context "when proposal has a state of evaluation and evaluation is not overdue" do
      let(:evaluating_days_overdue) { 7 }

      it "proposals don't have .text-alert" do
        expect(page).not_to have_css(".help-text-overdue.text-alert")
      end

      it "proposals with :evaluating and :not_answered have .text-warning" do
        expect(page).to have_css(".help-text-overdue.text-warning", count: 2)
      end

      it "proposal with :accepted does not have .help-text-overdue" do
        expect(page).not_to have_css(".help-text-overdue", count: 1)
      end
    end
  end

  context "when overdue days to answer are shorter" do
    let(:unanswered_days_overdue) { 7 }

    context "when proposal has a state of evaluation and evaluation is overdue" do
      let(:evaluating_days_overdue) { 2 }

      it "proposals with :not_answered and :evaluating have .text-alert" do
        expect(page).to have_css(".help-text-overdue.text-alert", count: 2)
      end

      it "proposals with :not_answered and :evaluating don't have .text-warning" do
        expect(page).not_to have_css(".help-text-overdue.text-warning")
      end

      it "proposal with :accepted does not have .help-text-overdue" do
        expect(page).not_to have_css(".help-text-overdue", count: 1)
      end
    end

    context "when proposal has a state of evaluation and evaluation is not overdue" do
      let(:evaluating_days_overdue) { 7 }

      it "proposals with :not_answered has .text-alert" do
        expect(page).to have_css(".help-text-overdue.text-alert", count: 1)
      end

      it "proposal with :evaluating has .text-warning" do
        expect(page).to have_css(".help-text-overdue.text-warning", count: 1)
      end

      it "proposal with :accepted does not have .help-text-overdue" do
        expect(page).not_to have_css(".help-text-overdue", count: 1)
      end
    end
  end
end
