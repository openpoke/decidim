# frozen_string_literal: true

module Decidim
  class InvitedToGroupEvent < Decidim::Events::SimpleEvent
    delegate :url_helpers, to: "Decidim::Core::Engine.routes"

    i18n_attributes :user_group_name
    i18n_attributes :groups_profile_tab_path

    def resource_url
      url_helpers.profile_url(
        user_group_nickname,
        host: user.organization.host
      )
    end

    def resource_path
      url_helpers.profile_path(user_group_nickname)
    end

    def groups_profile_tab_path
      url_helpers.profile_groups_path(user.nickname)
    end

    def user_group_nickname
      extra["user_group_nickname"]
    end

    def user_group_name
      extra["user_group_name"]
    end

    def user_group_invitation
      extra["user_group_invitation"]
    end

    def action
      [
        "buttons",
        [
          {
            url: url_helpers.group_invite_path(user_group_nickname, user_group_invitation),
            icon: "check-line",
            method: "patch",
            i18n_label: "decidim.group_invites.accept_invitation"
          },
          {
            url: url_helpers.group_invite_path(user_group_nickname, user_group_invitation),
            icon: "close-circle-line",
            method: "delete",
            i18n_label: "decidim.group_invites.reject_invitation"
          }
        ]
      ]
    end
  end
end
