# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Proposals
    # This cell renders the List (:l) proposal card
    # for an instance of a Proposal
    class ProposalLCell < Decidim::CardLCell
      alias proposal model

      def title
        present(proposal).title(html_escape: true)
      end

      private

      def metadata_cell
        "decidim/proposals/proposal_metadata"
      end

      def has_actions?
        model.component.current_settings.votes_enabled? && !model.draft? && !model.withdrawn? && !model.rejected?
      end

      def proposal_vote_cell
        "decidim/proposals/proposal_vote"
      end
    end
  end
end
