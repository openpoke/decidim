# frozen_string_literal: true

shared_examples "manage process steps examples" do
  let(:active) { false }
  let!(:process_step) do
    create(
      :participatory_process_step,
      participatory_process: participatory_process,
      active: active
    )
  end
  let(:attributes) { attributes_for(:participatory_process_step, participatory_process: participatory_process) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_admin_participatory_processes.edit_participatory_process_path(participatory_process)
    click_link "Phases"
  end

  it_behaves_like "having a rich text editor for field", ".tabs-content[data-tabs-content='participatory_process_step-description-tabs']", "full" do
    before { find(".card-title a.button").click }
  end

  it "creates a new participatory_process", versioning: true do
    find(".card-title a.button").click

    fill_in_i18n(
      :participatory_process_step_title,
      "#participatory_process_step-title-tabs",
      **attributes[:title].except("machine_translations")
    )
    fill_in_i18n_editor(
      :participatory_process_step_description,
      "#participatory_process_step-description-tabs",
      **attributes[:description].except("machine_translations")
    )
    fill_in_i18n(:participatory_process_step_cta_text, "#participatory_process_step-cta_text-tabs", **attributes[:cta_text].except("machine_translations"))

    page.execute_script("$('#participatory_process_step_start_date').focus()")
    page.find(".datepicker-dropdown .day:not(.new)", text: "12").click
    page.execute_script("$('#participatory_process_step_end_date').focus()")
    page.find(".datepicker-dropdown .day", text: "22").click

    within ".new_participatory_process_step" do
      # For some reason, the form submit button click can fail unless the page
      # is first scrolled to this element
      # Got the idea from:
      # https://stackoverflow.com/a/39103252
      page.scroll_to(find(".form-general-submit"))
      find(".form-general-submit").click
    end

    expect(page).to have_admin_callout("successfully")

    within "#steps table" do
      expect(page).to have_content(translated(attributes[:title]))
      expect(page).to have_content("12,")
      expect(page).to have_content("22,")
    end
    visit decidim_admin.root_path
    expect(page).to have_content("created the #{translated(attributes[:title])} phase in")
  end

  it "updates a participatory_process_step", versioning: true do
    within "#steps" do
      within find("tr", text: translated(process_step.title)) do
        click_link "Edit"
      end
    end

    within ".edit_participatory_process_step" do
      fill_in_i18n(:participatory_process_step_title, "#participatory_process_step-title-tabs", **attributes[:title].except("machine_translations"))
      fill_in_i18n_editor(:participatory_process_step_description, "#participatory_process_step-description-tabs", **attributes[:description].except("machine_translations"))
      fill_in_i18n(:participatory_process_step_cta_text, "#participatory_process_step-cta_text-tabs", **attributes[:cta_text].except("machine_translations"))

      find("*[type=submit]").click
    end

    expect(page).to have_admin_callout("successfully")

    within "#steps table" do
      expect(page).to have_content(translated(attributes[:title]))
      click_link(translated(attributes[:title]))
    end

    visit decidim_admin.root_path
    expect(page).to have_content("updated the #{translated(attributes[:title])} phase in")
  end

  context "when deleting a participatory process step" do
    let!(:process_step2) { create(:participatory_process_step, participatory_process: participatory_process) }

    before do
      visit current_path
    end

    it "deletes a participatory_process_step" do
      within find("tr", text: translated(process_step2.title)) do
        accept_confirm { click_link "Delete" }
      end

      expect(page).to have_admin_callout("successfully")

      within "#steps table" do
        expect(page).to have_no_content(translated(process_step2.title))
      end
    end
  end

  context "when activating a step" do
    it "activates a step" do
      within find("tr", text: translated(process_step.title)) do
        click_link "Activate"
      end

      within find("tr", text: translated(process_step.title)) do
        expect(page).to have_no_content("Activate")
      end
    end
  end
end
