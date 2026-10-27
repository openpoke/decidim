# frozen_string_literal: true

module Decidim
  # This cell is used to render a collection of linked resources for a
  # resource. It is based on the equivalent helper method
  # linked_resources_for.
  #
  # The `model` must be a resource to get the links from.
  #
  # Available options
  #  - `:type` => The String type fo the resources we want to render.
  #               Required.
  #  - `:link_name` => The String name of the link between the resources.
  #                    Required.
  #
  # Example:
  #
  #   cell(
  #     "decidim/linked_resources_for",
  #     result,
  #     type: :proposals,
  #     link_name: "included_proposals"
  #   )
  class LinkedResourcesForCell < Decidim::ViewModel
    include Cell::ViewModel::Partial

    alias resource model

    def show
      return if linked_resources.blank?

      render :show
    end

    private

    def linked_resources
      @linked_resources ||= resource.linked_resources(type, link_name, cross_space: true)
                                    .select { |linked_resource| visible_resource?(linked_resource) }
                                    .group_by { |linked_resource| linked_resource.class.name }
    end

    # Resources from other participatory spaces are only shown when their space is visible
    def visible_resource?(linked_resource)
      linked_resource.try(:participatory_space) == resource.try(:participatory_space) || linked_resource.visible?
    end

    def type
      options[:type]
    end

    def link_name
      options[:link_name]
    end
  end
end
