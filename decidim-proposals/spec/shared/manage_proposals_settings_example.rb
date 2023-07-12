# frozen_string_literal: true

shared_examples "manage settings" do
  let(:rich_text_editor_enabled) { true }
  let(:organization) { create(:organization, rich_text_editor_in_public_views: rich_text_editor_enabled) }

  before do
    click_link "Components"
    click_button "Add component"
    click_link "Proposals"
  end

  context "when rich text editor is enabled" do
    it "shows the rich text editor in the body template setting" do
      within ".new_proposal_body_template_container" do
        expect(page).to have_css(".editor-toolbar")
      end
      expect(page).to have_content("New proposal body template")
    end
  end

  context "when rich text editor is disabled" do
    let(:rich_text_editor_enabled) { false }

    it "does not show the rich text editor in the body template setting" do
      within ".new_proposal_body_template_container" do
        expect(page).not_to have_css(".editor-toolbar")
      end
    end
  end
end
