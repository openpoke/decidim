# frozen_string_literal: true

module Decidim
  module Proposals
    module Admin
      class ProposalsValuatorMailer < Decidim::ApplicationMailer
        include Decidim::TranslationsHelper
        include Decidim::SanitizeHelper
        include Decidim::ApplicationHelper

        def notify_proposals_valuator(user, admin, proposals, proposal)
          @valuator_user = user
          @admin = admin
          @proposals = proposals
          @proposal = proposal
          @organization = user.organization

          mail to: "#{user.name} <#{user.email}>",
               from: "#{admin.name}, #{admin.email}",
               subject: t(".subject")
        end
      end
    end
  end
end
