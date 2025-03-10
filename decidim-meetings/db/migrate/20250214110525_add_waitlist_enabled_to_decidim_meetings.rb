# frozen_string_literal: true

class AddWaitlistEnabledToDecidimMeetings < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_meetings_meetings, :waitlist_enabled, :boolean, default: false, null: false
  end
end
