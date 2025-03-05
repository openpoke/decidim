# frozen_string_literal: true

class AddRegisteredOnlyToDecidimShareTokens < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_share_tokens, :registered_only, :boolean
  end
end
