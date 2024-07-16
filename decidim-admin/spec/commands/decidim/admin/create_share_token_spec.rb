# frozen_string_literal: true

require "spec_helper"

module Decidim::Admin
  describe CreateShareToken do
    subject { described_class.new(form) }

    let(:organization) { create(:organization) }
    let(:current_user) { create(:user, :admin, organization:) }
    let(:component) { create(:component, participatory_space: create(:participatory_process, organization:)) }

    let(:form) do
      ShareTokenForm.from_params(
        token:,
        expires_at:,
        automatic_token:,
        no_expiration:
      ).with_context(
        current_user:,
        current_organization: organization,
        component:
      )
    end

    let(:token) { "ZHLABC123" }
    let(:expires_at) { Time.zone.today + 10.days }
    let(:automatic_token) { false }
    let(:no_expiration) { false }
    let(:form_invalid) { false }

    context "when the form is valid" do
      it "creates a share token" do
        expect { subject.call }.to change(Decidim::ShareToken, :count).by(1)

        share_token = Decidim::ShareToken.last
        expect(share_token.token).to eq(token)
        expect(share_token.expires_at).to eq(expires_at)
        expect(share_token.organization).to eq(organization)
        expect(share_token.user).to eq(current_user)
        expect(share_token.token_for).to eq(component)
      end

      it "broadcasts :ok with the resource" do
        expect(subject).to receive(:broadcast).with(:ok, instance_of(Decidim::ShareToken))
        subject.call
      end
    end

    context "when the form is invalid" do
      let(:form_invalid) { true }

      before do
        allow(form).to receive(:invalid?).and_return(true)
      end

      it "does not create a share token" do
        expect { subject.call }.not_to(change(Decidim::ShareToken, :count))
      end

      it "broadcasts :invalid" do
        expect(subject).to receive(:broadcast).with(:invalid)
        subject.call
      end
    end
  end
end
