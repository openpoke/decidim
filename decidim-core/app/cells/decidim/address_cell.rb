# frozen_string_literal: true

module Decidim
  # This cell renders the address of a meeting.
  class AddressCell < Decidim::ViewModel
    include Cell::ViewModel::Partial
    include LayoutHelper
    include Decidim::SanitizeHelper

    def details
      render
    end

    def has_location?
      model.respond_to?(:location)
    end

    def has_location_hints?
      model.respond_to?(:location_hints)
    end

    def location_hints
      decidim_sanitize(translated_attribute(model.location_hints))
    end

    def location
      return pending_address_text if pending_address?

      decidim_sanitize(translated_attribute(model.location))
    end

    def address
      decidim_sanitize(translated_attribute(model.address)) if model.respond_to?(:address) && model.address.present?
    end

    private

    def resource_icon
      icon "meetings", class: "icon--big", role: "img", "aria-hidden": true
    end

    def pending_address?
      address.blank? && model.location.is_a?(Hash) ? model.location.values.none?(&:present?) : model.location.blank?
    end

    def pending_address_text
      t("show.pending_address", scope: "decidim.meetings.meetings")
    end
  end
end
