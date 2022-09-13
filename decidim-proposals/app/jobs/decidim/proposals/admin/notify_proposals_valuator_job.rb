# frozen_string_literal: true

module Decidim
  module Proposals
    module Admin
      class NotifyProposalsValuatorJob < ApplicationJob
        def perform(user, current_user, proposals, proposal)
          ProposalsValuatorMailer.notify_proposals_valuator(user, current_user, proposals, proposal).deliver_later
        end
      end
    end
  end
end
