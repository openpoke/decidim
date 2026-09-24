# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TwoFactor
    describe PasskeyEnrollmentForm do
      subject { described_class.from_params(name:, credential:) }

      let(:name) { "My laptop" }
      let(:response) { { "clientDataJSON" => "data", "attestationObject" => "attestation" } }
      let(:credential) { { "type" => "public-key", "id" => "abc", "rawId" => "abc", "response" => response }.to_json }

      it "is valid and parses the credential" do
        expect(subject).to be_valid
        expect(subject.credential).to eq({ "type" => "public-key", "id" => "abc", "rawId" => "abc", "response" => response })
      end

      context "when the name carries spaces" do
        let(:name) { "  My laptop  " }

        it "is valid and normalized" do
          expect(subject).to be_valid
          expect(subject.name).to eq("My laptop")
        end
      end

      context "when the name is blank" do
        let(:name) { "   " }

        it "is valid without a name" do
          expect(subject).to be_valid
          expect(subject.name).to be_nil
        end
      end

      context "when the name is longer than allowed" do
        let(:name) { "x" * 65 }

        it { is_expected.not_to be_valid }
      end

      context "when the credential is blank" do
        let(:credential) { "" }

        it { is_expected.not_to be_valid }
      end

      context "when the credential is not JSON" do
        let(:credential) { "bogus" }

        it { is_expected.not_to be_valid }
      end

      context "when the credential is not a public key" do
        let(:credential) { { "type" => "password", "id" => "abc", "rawId" => "abc", "response" => response }.to_json }

        it { is_expected.not_to be_valid }
      end

      context "when the credential has no raw id" do
        let(:credential) { { "type" => "public-key", "id" => "abc", "response" => response }.to_json }

        it { is_expected.not_to be_valid }
      end

      context "when the response lacks the attestation" do
        let(:response) { { "clientDataJSON" => "data" } }

        it { is_expected.not_to be_valid }
      end
    end
  end
end
