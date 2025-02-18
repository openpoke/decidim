# frozen_string_literal: true

module Decidim
  module Meetings
    # This cell renders the button to join a waitlist.
    class JoinWaitlistButtonCell < Decidim::ViewModel
      include MeetingCellsHelper

      def show
        return unless model.waitlist_enabled? && !model.has_available_slots? && model.can_be_joined_by?(current_user)
        return if model.has_registration_for?(current_user)

        render
      end

      private

      def current_component
        model.component
      end

      def button_classes
        "button button__sm button__transparent-secondary w-full"
      end

      def i18n_join_waitlist_text
        return if !model.waitlist_enabled? && model.has_available_slots?

        I18n.t("add_to_waitlist", scope: "decidim.meetings.meetings.show")
      end

      def icon_name
        "list-ordered"
      end

      def registration_form
        @registration_form ||= Decidim::Meetings::JoinMeetingForm.new
      end
    end
  end
end
