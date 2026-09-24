# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TwoFactor
    describe PasskeyAuthenticator do
      include_context "with a fake passkey client"

      let(:organization) { create(:organization) }
      let(:user) { create(:user, :confirmed, organization:) }
      let(:passkey) { create(:passkey_authenticator, user:) }

      it "allows several passkeys per user" do
        create(:passkey_authenticator, user:)

        expect(build(:passkey_authenticator, user:)).to be_valid
      end

      it "rejects a name longer than 64 characters" do
        expect(build(:passkey_authenticator, user:, name: "x" * 65)).not_to be_valid
      end

      describe "#credential_descriptor" do
        it "carries the transports only when some were stored" do
          expect(passkey.credential_descriptor).to eq({ type: "public-key", id: passkey.external_id })

          passkey.update!(metadata: { "transports" => ["hybrid"] })

          expect(passkey.credential_descriptor).to eq({ type: "public-key", id: passkey.external_id, transports: ["hybrid"] })
        end
      end

      describe ".user_handle_for" do
        it "reuses the handle of an existing passkey and generates one otherwise" do
          expect(described_class.user_handle_for(user)).to be_present

          passkey.update!(metadata: { "user_handle" => "stored-handle" })

          expect(described_class.user_handle_for(user)).to eq("stored-handle")
        end
      end

      context "with an enrolled passkey" do
        let!(:enrolled) { enroll_fake_passkey(user, fake_client, relying_party) }
        let(:challenge) { create(:two_factor_challenge, user:, method_type: "passkey") }
        let(:options) { described_class.assertion_options(challenge, origin) }
        let(:credential) { fake_client.get(challenge: options.challenge).to_json }
        let(:form) { PasskeyChallengeForm.from_params(credential:, method_name: "passkey") }

        describe ".find_for" do
          it "returns the passkey the credential belongs to" do
            expect(described_class.find_for(user, form)).to eq(enrolled)
          end

          it "returns nothing for a credential no passkey holds" do
            form = PasskeyChallengeForm.from_params(credential: { type: "public-key", id: "unknown" }.to_json)

            expect(described_class.find_for(user, form)).to be_nil
          end
        end

        describe ".assertion_options" do
          it "stores the ceremony on the challenge" do
            options

            expect(challenge.reload.metadata["webauthn"]).to eq({ "challenge" => options.challenge, "origin" => origin })
          end

          it "lists the enrolled credential with its transports" do
            allowed = JSON.parse(options.to_json)["allowCredentials"]

            expect(allowed.map { |descriptor| descriptor["id"] }).to eq([enrolled.external_id])
            expect(allowed.first["transports"]).to eq(["internal"])
          end
        end

        describe "#verify" do
          subject { enrolled.verify(form, challenge) }

          it "accepts the assertion, records the use and clears the ceremony" do
            expect(subject).to be(true)
            expect(enrolled.reload.sign_count).to be_positive
            expect(challenge.reload.metadata).not_to have_key("webauthn")
          end

          context "when the assertion was signed for another ceremony" do
            let(:credential) { fake_client.get(challenge: relying_party.options_for_authentication(allow: [enrolled.external_id]).challenge).to_json }

            it "rejects it and clears the ceremony" do
              options

              expect(subject).to be(false)
              expect(challenge.reload.metadata).not_to have_key("webauthn")
            end
          end

          context "when no ceremony is stored" do
            let(:credential) { fake_client.get(challenge: relying_party.options_for_authentication(allow: [enrolled.external_id]).challenge).to_json }

            it "rejects the assertion" do
              expect(subject).to be(false)
            end
          end

          context "when the sign count goes backwards" do
            before { enrolled.update!(sign_count: 1_000) }

            it "rejects the assertion" do
              expect(subject).to be(false)
              expect(enrolled.reload.sign_count).to eq(1_000)
            end
          end
        end
      end
    end
  end
end
