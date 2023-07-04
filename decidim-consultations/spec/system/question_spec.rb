# frozen_string_literal: true

require "spec_helper"

describe "Question", type: :system do
  let(:organization) { create(:organization) }
  let!(:consultation) { create(:consultation, :published, organization: organization) }
  let(:question_context) { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
  let(:what_is_decided) { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
  let(:previous_question) { create :question, consultation: consultation }
  let(:question) { create :question, consultation: consultation, question_context: question_context, what_is_decided: what_is_decided }
  let(:next_question) { create :question, consultation: consultation }

  context "when shows question information" do
    before do
      switch_to_host(organization.host)
      visit decidim_consultations.question_path(question)
    end

    context "when displaying question context" do
      it_behaves_like "has embedded video in description", :question_context, count: 2 do
        before { click_button("Read more") }
      end
    end

    context "when displaying what is decided" do
      it_behaves_like "has embedded video in description", :what_is_decided do
        before { click_button("Read more") }
      end
    end

    it "Shows the basic question data" do
      expect(page).to have_i18n_content(question.promoter_group)
      expect(page).to have_i18n_content(question.scope.name)
      expect(page).to have_i18n_content(question.participatory_scope)
      expect(page).to have_i18n_content(question.question_context)

      expect(page).not_to have_i18n_content(question.what_is_decided)
    end

    it "Shows the technical data" do
      expect(page).to have_i18n_content(question.promoter_group)
      expect(page).to have_i18n_content(question.scope.name)
      expect(page).to have_i18n_content(question.participatory_scope)
      expect(page).to have_i18n_content(question.question_context)

      click_button("Read more")

      expect(page).to have_i18n_content(question.what_is_decided)
    end

    context "when is the only published question" do
      it "doesn't show the previous/next question button" do
        expect(page).not_to have_content("Previous question")
        expect(page).not_to have_content("Next question")
      end
    end
  end

  context "when previous question is published" do
    before do
      previous_question.publish!
      question.publish!
      switch_to_host(organization.host)
      visit decidim_consultations.question_path(question)
    end

    it "shows the previous/next question button" do
      expect(page).to have_content("Previous question")
      expect(page).to have_content("Next question")
    end

    context "when showing the previous/next question button" do
      let(:previous_button) { page.find("a", text: "Previous question") }
      let(:next_button) { page.find("a", text: "Next question") }

      it "enables the previous button when viewing the first question" do
        expect(previous_button[:class]).not_to include("disabled")
      end

      it "disables the next button when viewing the last question" do
        expect(next_button[:class]).to include("disabled")
      end
    end
  end

  context "when no question is published" do
    let(:user) { create(:user, :admin, :confirmed, organization: organization) }
    let(:previous_question) { create :question, :unpublished, consultation: consultation }
    let(:question) { create :question, :unpublished, consultation: consultation }
    let(:next_question) { create :question, :unpublished, consultation: consultation }

    before do
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit decidim_consultations.question_path(question)
    end

    it "hides the previous/next question button" do
      expect(page).not_to have_content("Previous question")
      expect(page).not_to have_content("Next question")
    end
  end

  context "when next question is published" do
    before do
      question.publish!
      next_question.publish!
      switch_to_host(organization.host)
      visit decidim_consultations.question_path(question)
    end

    it "shows the previous/next question button" do
      expect(page).to have_content("Previous question")
      expect(page).to have_content("Next question")
    end

    context "when showing the previous/next question button" do
      let(:previous_button) { page.find("a", text: "Previous question") }
      let(:next_button) { page.find("a", text: "Next question") }

      it "disables the previous button when viewing the first question" do
        expect(previous_button[:class]).to include("disabled")
      end

      it "enables the next button when viewing the last question" do
        expect(next_button[:class]).not_to include("disabled")
      end
    end
  end

  context "when finished consultations" do
    context "and published results" do
      let(:consultation) { create :consultation, :finished, :published, :published_results, organization: organization }
      let(:response) { create :response, question: question }
      let!(:vote) { create :vote, question: question, response: response }

      before do
        switch_to_host(organization.host)
        visit decidim_consultations.question_path(question)
      end

      it "Has the results" do
        expect(page).to have_content("RESULTS")
        expect(page).to have_i18n_content(response.title)
        expect(page).to have_content(response.votes_count)
      end
    end
  end

  context "when question has no hero image" do
    let(:question_without_hero) { create :question, consultation: consultation, hero_image: nil }

    before do
      switch_to_host(organization.host)
      visit decidim_consultations.question_path(question_without_hero)
    end

    it "Shows the basic question data" do
      expect(page).to have_i18n_content(question_without_hero.promoter_group)
      expect(page).to have_i18n_content(question_without_hero.scope.name)
      expect(page).to have_i18n_content(question_without_hero.participatory_scope)
      expect(page).to have_i18n_content(question_without_hero.question_context)
    end
  end
end
