# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TwoFactor
    describe EnrollPasskey do
      subject { described_class.new(user, form, ceremony) }

      include_context "with a fake passkey client"

      let(:organization) { create(:organization) }
      let(:user) { create(:user, :confirmed, organization:) }
      let(:name) { "My laptop" }
      let(:user_handle) { WebAuthn.generate_user_id }
      let(:options) { relying_party.options_for_registration(user: { id: user_handle, name: user.email }) }
      let(:user_verified) { true }
      let(:credential) { fake_client.create(challenge: options.challenge, user_verified:).to_json }
      let(:ceremony) { { relying_party:, challenge: options.challenge, user_handle: } }
      let(:form) { PasskeyEnrollmentForm.from_params(name:, credential:) }

      it_behaves_like "an enrollment issuing recovery codes"

      context "when everything is ok" do
        it "attaches a confirmed passkey with the ceremony data" do
          expect { subject.call }.to change(PasskeyAuthenticator, :count).by(1)

          passkey = PasskeyAuthenticator.find_by(user:)
          expect(passkey).to be_confirmed
          expect(passkey.name).to eq("My laptop")
          expect(passkey.metadata["user_handle"]).to eq(user_handle)
          expect(passkey.metadata["transports"]).to eq(["internal"])
        end
      end

      context "when the device did not verify the user" do
        let(:user_verified) { false }

        it "broadcasts invalid" do
          expect { subject.call }.to broadcast(:invalid)
        end
      end

      context "when the stored challenge does not match" do
        let(:ceremony) { { relying_party:, challenge: relying_party.options_for_registration(user: { id: user_handle, name: user.email }).challenge, user_handle: } }

        it "broadcasts invalid and attaches nothing" do
          expect { subject.call }.to broadcast(:invalid)
          expect(PasskeyAuthenticator.where(user:)).to be_empty
        end
      end

      context "when no ceremony is pending" do
        let(:ceremony) { { relying_party:, challenge: nil, user_handle: } }

        it "broadcasts invalid" do
          expect { subject.call }.to broadcast(:invalid)
        end
      end

      context "when the credential is already registered" do
        before { described_class.call(user, form, ceremony) }

        it "broadcasts invalid" do
          expect { subject.call }.to broadcast(:invalid)
        end
      end
    end
  end
end
