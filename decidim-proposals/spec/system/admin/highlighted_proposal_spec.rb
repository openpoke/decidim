# frozen_string_literal: true

require "spec_helper"

describe "Highlighted proposal", type: :system do
  let(:admin) { create :user, :admin, :confirmed }
  let(:organization) { admin.organization }
  let!(:participatory_process) { create(:participatory_process, organization: organization) }
  let!(:proposal_component) { create(:proposal_component, participatory_space: participatory_process) }
  let!(:proposals) do
    [
      create(:proposal, :not_answered, id: 1, created_at: 9.days.ago, published_at: 9.days.ago, component:
        proposal_component),
      create(:proposal, :not_answered, id: 2, created_at: 5.days.ago, published_at: 5.days.ago, component:
        proposal_component),
      create(:proposal, :with_answer, id: 3, created_at: 9.days.ago, published_at: 9.days.ago, component:
        proposal_component)
    ]
  end

  before do
    switch_to_host(organization.host)
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

  context "when proposal with overdue and not answered" do
    it "columns have the class admin-highlighted" do
      expect(page).to have_css("tr.admin-highlighted", count: 1)
    end
  end

  context "when proposal without overdue and not answered" do
    it "columns don't have the class admin-highlighted" do
      expect(page).not_to have_css("tr.admin-highlighted", count: 2)
    end
  end

  context "when proposal with overdue but answered" do
    it "columns don't have the class admin-highlighted" do
      expect(page).not_to have_css("tr.admin-highlighted", count: 3)
    end
  end
end
