# frozen_string_literal: true

module Decidim
  module Meetings
    # This cell renders the button to cancel a meeting registration.
    class CancelRegistrationMeetingButtonCell < Decidim::ViewModel
      include MeetingCellsHelper

      def show
        return unless model.can_be_joined_by?(current_user)
        return unless model.has_registration_for?(current_user)

        render
      end

      private

      def current_component
        model.component
      end

      def registration_status
        model.registrations.find_by(user: current_user)&.status
      end

      def cancel_button_text
        scope = "decidim.meetings.meetings.show"
        registration_status == "on_waiting_list" ? I18n.t("cancel_waitlist", scope:) : I18n.t("leave", scope:)
      end

      def button_classes
        "button button__sm button__transparent-secondary w-full"
      end

      def icon_name
        "calendar-close-line"
      end

      def registration_form
        @registration_form ||= Decidim::Meetings::JoinMeetingForm.new
      end
    end
  end
end
