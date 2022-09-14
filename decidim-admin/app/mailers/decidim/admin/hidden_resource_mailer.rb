# frozen_string_literal: true

module Decidim
  module Admin
    # A custom mailer to mail Decidim users
    # that they have been hidden
    class HiddenResourceMailer < Decidim::ApplicationMailer
      include Decidim::TranslationsHelper
      include Decidim::SanitizeHelper
      include Decidim::ApplicationHelper
      include Decidim::TranslatableAttributes

      helper Decidim::ResourceHelper
      helper Decidim::TranslationsHelper
      helper Decidim::ApplicationHelper

      def notify_mail(resource, authors_email, authors_name, reason)
        @authors_email = authors_email
        @authors_name = authors_name
        @organization = resource.organization
        @resource = resource
        @reason = reason

        mail(to: "#{authors_email.join(',')}",
             subject: I18n.t("decidim.admin.hidden_resource_mailer.notify_mail.subject",
                             organization_name: @organization.name))
      end
    end
  end
end
