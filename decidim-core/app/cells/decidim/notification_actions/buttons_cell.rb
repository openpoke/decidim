# frozen_string_literal: true

require "cell/partial"

module Decidim
  module NotificationActions
    class ButtonsCell < BaseCell
      def show
        return unless data.present? && data.respond_to?(:map)

        render :show
      end

      def buttons
        @buttons ||= data.map do |item|
          [
            item["label"].presence || I18n.t(item["i18n_label"]),
            item["url"],
            {
              class: "button button__sm #{class_for(item)}",
              remote: true,
              data: { "notification-action" => "button", "notification-after-action" => notification_path(model) }
            }
          ].tap do |button|
            button[0] << icon(item["icon"]) if item["icon"].present?
            button[2][:method] = item["method"] if item["method"].in?(%w(get patch put delete post))
          end
        end
      end

      private

      def class_for(item)
        (item["class"].presence || "button__transparent-secondary")
      end
    end
  end
end
