# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TwoFactor
    describe PasskeyChallengeForm do
      subject { described_class.from_params(method_name: "passkey", credential:) }

      let(:response) { { "clientDataJSON" => "data", "authenticatorData" => "auth", "signature" => "sig" } }
      let(:credential) { { "type" => "public-key", "id" => "abc", "rawId" => "abc", "response" => response }.to_json }

      it { is_expected.to be_valid }

      context "when the response lacks the signature" do
        let(:response) { { "clientDataJSON" => "data", "authenticatorData" => "auth" } }

        it { is_expected.not_to be_valid }
      end
    end
  end
end
