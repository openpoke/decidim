# frozen_string_literal: true

module Decidim
  module Meetings
    # Exposes the registration resource so users can join and leave meetings.
    class RegistrationsController < Decidim::Meetings::ApplicationController
      include Decidim::Forms::Concerns::HasQuestionnaire

      def answer
        enforce_permission_to :join, :meeting, meeting: meeting

        @form = form(Decidim::Forms::QuestionnaireForm).from_params(params, session_token: session_token)

        waitlist = ActiveModel::Type::Boolean.new.cast(params[:waitlist])
        command = waitlist ? JoinWaitlist : JoinMeeting

        command.call(meeting, current_user, @form) do
          on(:ok) do
            flash[:notice] = I18n.t("registrations.#{waitlist ? "waitlist" : "create"}.success", scope: "decidim.meetings")
            redirect_to after_answer_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("registrations.#{waitlist ? "waitlist" : "create"}.invalid", scope: "decidim.meetings")
            render template: "decidim/forms/questionnaires/show", status: :unprocessable_entity
          end

          on(:invalid_form) do
            flash.now[:alert] = I18n.t("answer.invalid", scope: i18n_flashes_scope)
            render template: "decidim/forms/questionnaires/show", status: :unprocessable_entity
          end
        end
      end

      def create
        enforce_permission_to :register, :meeting, meeting: meeting

        @form = JoinMeetingForm.from_params(params)

        JoinMeeting.call(meeting, current_user, @form) do
          on(:ok) do
            flash[:notice] = I18n.t("registrations.create.success", scope: "decidim.meetings")
            redirect_after_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("registrations.create.invalid", scope: "decidim.meetings")
            redirect_after_path
          end
        end
      end

      def join_waitlist
        enforce_permission_to(:join_waitlist, :meeting, meeting: meeting)

        @form = JoinMeetingForm.from_params(params).with_context(current_user: current_user)

        JoinWaitlist.call(meeting, current_user, @form) do
          on(:ok) do
            flash[:notice] = I18n.t("registrations.waitlist.success", scope: "decidim.meetings")
            redirect_after_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("registrations.waitlist.invalid", scope: "decidim.meetings")
            redirect_after_path
          end
        end
      end

      def destroy
        enforce_permission_to :leave, :meeting, meeting: meeting

        status = registration.status

        LeaveMeeting.call(meeting, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("registrations.destroy.#{status}.success", scope: "decidim.meetings")
            redirect_after_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("registrations.destroy.#{status}.invalid", scope: "decidim.meetings")
            redirect_after_path
          end
        end
      end

      def decline_invitation
        enforce_permission_to :decline_invitation, :meeting, meeting: meeting

        DeclineInvitation.call(meeting, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("registrations.decline_invitation.success", scope: "decidim.meetings")
            redirect_after_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("registrations.decline_invitation.invalid", scope: "decidim.meetings")
            redirect_after_path
          end
        end
      end

      def allow_answers?
        return false unless meeting.registrations_enabled? && meeting.registration_form_enabled?

        meeting.has_available_slots? || (meeting.waitlist_enabled? && request.path.include?("join_waitlist"))
      end

      def after_answer_path
        meeting_path(meeting)
      end

      # You can implement this method in your controller to change the URL
      # where the questionnaire will be submitted.
      def update_url
        answer_meeting_registration_path(meeting_id: meeting.id, waitlist: params[:waitlist] || request.path.include?("join_waitlist"))
      end

      def questionnaire_for
        meeting
      end

      private

      def meeting
        @meeting ||= Meeting.where(component: current_component).find(params[:meeting_id])
      end

      def registration
        @registration ||= meeting.registrations.find_by(user: current_user)
      end

      def redirect_after_path
        redirect_to meeting_path(meeting)
      end

      def user_has_no_permission_path
        return meeting_path(meeting) if user_signed_in?

        decidim.new_user_session_path
      end
    end
  end
end
