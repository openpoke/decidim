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

      def notify_mail(resource, author, reason)
        @author = author
        @organization = author.organization
        @resource = resource
        @reason = reason
        mail(to: author.email, subject: I18n.t(
          "decidim.admin.hidden_resource_mailer.notify_mail.subject",
          organization_name: @organization.name
        ))
      end
    end
  end
end
