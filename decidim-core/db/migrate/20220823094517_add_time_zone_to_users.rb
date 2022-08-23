# frozen_string_literal: true

class AddTimeZoneToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :decidim_users, :time_zone, :string, limit: 255, default: "UTC"
  end
end
