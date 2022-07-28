# frozen_string_literal: true

module Decidim
  module Proposals
    module ProposalPresenterHelper
      def not_from_collaborative_draft(proposal)
        proposal.linked_resources(:proposals, "created_from_collaborative_draft").empty?
      end

      def not_from_participatory_text(proposal)
        proposal.participatory_text_level.nil?
      end

      # If the proposal is official or the rich text editor is enabled on the
      # frontend, the proposal body is considered as safe content; that's unless
      # the proposal comes from a collaborative_draft or a participatory_text.
      def safe_content?
        rich_text_editor_in_public_views? && not_from_collaborative_draft(@proposal) ||
          (@proposal.official? || @proposal.official_meeting?) && not_from_participatory_text(@proposal)
      end

      def render_proposal_title(proposal)
        Decidim::Proposals::ProposalPresenter.new(proposal).title(links: true, html_escape: true)
      end

      # If the content is safe, HTML tags are sanitized, otherwise, they are stripped.
      def render_proposal_body(proposal)
        Decidim::ContentProcessor.render(render_sanitized_content(proposal, :body), "div")
      end
    end
  end
end
