# frozen_string_literal: true

require "spec_helper"

module Decidim::Proposals::Admin
  describe ProposalsValuatorMailer, type: :mailer do
    include ActionView::Helpers::SanitizeHelper

    let(:organization) { create(:organization) }
    let(:participatory_process) { create(:participatory_process, organization: organization) }
    let(:proposals_component) { create(:component, manifest_name: "proposals", participatory_space: participatory_process) }
    let(:user) { create(:user, organization: organization, name: "Tamilla", email: "valuator@example.org") }
    let(:admin) { create(:user, :admin, organization: organization, name: "Mark") }
    let(:proposal) { create(:proposal, component: proposals_component) }
    let(:proposals) { create_list(:proposal, 3, component: proposals_component) }

    context "when valuator assigned" do
      let(:mail) { described_class.notify_proposals_valuator(user, admin, proposals, proposal) }
      let(:proposal_url) { Decidim::ResourceLocatorPresenter.new(proposal).url }

      it "set subject email" do
        expect(mail.subject).to eq("A proposal evaluator has been assigned")
      end

      it "set email from" do
        expect(mail.from).to eq([Decidim::Organization.first.smtp_settings["from"]])
      end

      it "set email to" do
        expect(mail.to).to eq(["valuator@example.org"])
      end

      it "body email has valuator name" do
        expect(email_body(mail)).to include("Tamilla")
      end

      it "body email has admin name" do
        expect(email_body(mail)).to include("Mark")
      end

      # it "body email has proposal links" do
      #   expect(email_body(mail)).to have_link(proposal.title["en"], href: proposal_url)
      # end
    end
  end
end
