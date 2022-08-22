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
      create(:proposal, :with_answer, created_at: 10.days.ago, published_at: 10.days.ago, component:
        proposal_component)
    ]
  end

  let(:days_overdue) { 17 }

  before do
    switch_to_host(organization.host)
    allow(Decidim::Proposals.config).to receive(:unanswered_proposals_overdue).and_return days_overdue
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
    let(:days_overdue) { 12 }

    it "no proposals has overdue" do
      expect(page).not_to have_css("tr.admin-highlighted")
    end
  end

  context "when overdue days is shorter" do
    let(:days_overdue) { 3 }

    it "all unanswered proposals are highlighted" do
      expect(page).to have_css("tr.admin-highlighted", count: 1)
      expect(page).not_to have_css("tr.admin-highlighted", count: 2)
    end
  end

  context "when overdue days is zero" do
    let(:days_overdue) { 0 }

    it "proposals are not highlighted" do
      expect(page).not_to have_css("tr.admin-highlighted")
    end
  end
end
