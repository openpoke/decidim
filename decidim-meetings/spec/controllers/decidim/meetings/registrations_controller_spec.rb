# frozen_string_literal: true

require "spec_helper"

module Decidim::Meetings
  describe RegistrationsController do
    routes { Decidim::Meetings::Engine.routes }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, :confirmed, organization:) }
    let(:participatory_process) { create(:participatory_process, organization:) }
    let(:component) { create(:meeting_component, participatory_space: participatory_process) }
    let(:meeting) { create(:meeting, :published, component:, registrations_enabled: true, available_slots: 10) }

    before do
      request.env["decidim.current_organization"] = organization
      request.env["decidim.current_participatory_space"] = participatory_process
      request.env["decidim.current_component"] = component
    end

    describe "POST create" do
      let(:params) { { meeting_id: meeting.id } }

      context "when user is authenticated" do
        before { sign_in user }

        context "with available slots" do
          it "creates registration and redirects" do
            expect do
              post :create, params: params
            end.to change(Registration, :count).by(1)

            expect(flash[:notice]).to eq(I18n.t("registrations.create.success", scope: "decidim.meetings"))
            expect(response).to redirect_to(meeting_path(meeting))
          end
        end

        context "when no available slots" do
          let(:meeting) { create(:meeting, component:, available_slots: 0, registrations_enabled: true, waitlist_enabled: false) }

          it "shows error message" do
            post :create, params: params

            expect(flash[:alert]).to eq(I18n.t("registrations.create.invalid", scope: "decidim.meetings"))
            expect(response).to redirect_to(meeting_path(meeting))
          end
        end
      end

      context "when user not authenticated" do
        it "redirects to login" do
          post :create, params: params
          expect(response).to redirect_to("/users/sign_in")
        end
      end
    end

    describe "POST answer" do
      let(:questionnaire) { create(:questionnaire, :with_questions, questionnaire_for: meeting) }
      let(:question) { questionnaire.questions.first }
      let(:params) do
        {
          meeting_id: meeting.id,
          waitlist: waitlist,
          questionnaire: {
            responses: [
              {
                body: "Answer",
                question_id: question.id
              }
            ],
            tos_agreement: true
          }
        }
      end
      let(:waitlist) { false }

      before do
        sign_in user
        meeting.update!(
          registrations_enabled: true,
          registration_form_enabled: true,
          questionnaire: questionnaire
        )
      end

      context "with valid params" do
        before do
          if waitlist
            meeting.update!(waitlist_enabled: true, available_slots: 0)
          else
            meeting.update!(available_slots: 5)
          end
        end

        context "when joining directly" do
          it "answers questionnaire and redirects" do
            puts "Test Params: #{params.inspect}"

            expect do
              post :answer, params: params
            end.to change { meeting.registrations.count }.by(1)

            expect(flash[:notice]).to eq(I18n.t("registrations.create.success", scope: "decidim.meetings"))
            expect(response).to redirect_to(meeting_path(meeting))
          end
        end

        context "when joining waitlist" do
          let(:waitlist) { true }

          it "adds user to waitlist and redirects" do
            expect do
              post :answer, params: params
            end.to change { meeting.registrations.where(status: :on_waiting_list).count }.by(1)

            expect(flash[:notice]).to eq(I18n.t("registrations.waitlist.success", scope: "decidim.meetings"))
            expect(response).to redirect_to(meeting_path(meeting))
          end
        end
      end

      context "with invalid params" do
        let(:params) do
          {
            meeting_id: meeting.id,
            waitlist: waitlist,
            questionnaire: { responses: [] } # Пустые ответы
          }
        end

        before do
          meeting.update!(available_slots: 0, waitlist_enabled: waitlist, registrations_enabled: true)
        end

        it "shows error message" do
          post :answer, params: params

          expected_key = waitlist ? "waitlist" : "create"
          expect(flash[:alert]).to eq(I18n.t("registrations.#{expected_key}.invalid", scope: "decidim.meetings"))
          expect(response).to render_template("decidim/forms/questionnaires/show")
        end
      end
    end

    describe "POST join_waitlist" do
      let(:meeting) { create(:meeting, component:, available_slots: available_slots, waitlist_enabled: true) }
      let(:params) { { meeting_id: meeting.id } }
      let(:available_slots) { 0 }

      before { sign_in user }

      context "when meeting has no available slots" do
        it "adds user to waitlist" do
          expect do
            post :join_waitlist, params: params
          end.to change(Registration.on_waiting_list, :count).by(1)

          expect(flash[:notice]).to eq(I18n.t("registrations.waitlist.success", scope: "decidim.meetings"))
          expect(response).to redirect_to(meeting_path(meeting))
        end
      end
    end

    describe "DELETE destroy" do
      let!(:registration) { create(:registration, meeting:, user:) }
      let(:params) { { meeting_id: meeting.id } }

      before { sign_in user }

      it "destroys registration" do
        expect do
          delete :destroy, params: params
        end.to change(Registration, :count).by(-1)

        expect(flash[:notice]).to match(/successfully/)
        expect(response).to redirect_to(meeting_path(meeting))
      end
    end
  end
end
