# frozen_string_literal: true

module Decidim
  module Meetings
    #  This command is executed when the user joins a waitlist for a meeting.
    class JoinWaitlist < Decidim::Command
      # Initializes a JoinWaitlist Command.
      #
      # meeting - The current instance of the meeting to be joined.
      # user - The user joining the waitlist.
      # registration_form - A form object with params; can be a questionnaire.
      def initialize(meeting, user, registration_form)
        @meeting = meeting
        @user = user
        @user_group = Decidim::UserGroup.find_by(id: registration_form.user_group_id)
        @registration_form = registration_form
      end

      # Joins the waitlist for the meeting if valid.
      #
      # Broadcasts :ok if successful, :invalid otherwise.
      def call
        return broadcast(:invalid) unless can_join_waitlist?
        return broadcast(:invalid_form) unless registration_form.valid?
        return broadcast(:invalid) if answer_questionnaire == :invalid

        meeting.with_lock do
          create_waitlist_entry
          send_waitlist_notification
        end
        follow_meeting
        broadcast(:ok)
      end

      private

      attr_reader :meeting, :user, :user_group, :registration, :registration_form

      def can_join_waitlist?
        meeting.waitlist_enabled? &&
          !meeting.registrations.exists?(user: user) &&
          !meeting.has_available_slots?
      end

      def create_waitlist_entry
        @registration = Decidim::Meetings::Registration.create!(
          meeting: meeting,
          user: user,
          user_group: user_group,
          public_participation: registration_form.public_participation,
          status: :on_waiting_list
        )
      end

      def send_waitlist_notification
        Decidim::EventsManager.publish(
          event: "decidim.events.meetings.meeting_waitlist_added",
          event_class: Decidim::Meetings::MeetingRegistrationNotificationEvent,
          resource: meeting,
          affected_users: [user]
        )
      end

      def answer_questionnaire
        return unless questionnaire?

        Decidim::Forms::AnswerQuestionnaire.call(registration_form, user, meeting.questionnaire) do
          on(:ok) do
            return :valid
          end

          on(:invalid) do
            return :invalid
          end
        end
      end

      def questionnaire?
        registration_form.model_name == "questionnaire"
      end

      def follow_meeting
        Decidim::CreateFollow.call(follow_form, user)
      end

      def follow_form
        Decidim::FollowForm
          .from_params(followable_gid: meeting.to_signed_global_id.to_s)
          .with_context(current_user: user)
      end
    end
  end
end
