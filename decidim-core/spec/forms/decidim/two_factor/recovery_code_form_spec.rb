# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TwoFactor
    describe RecoveryCodeForm do
      subject { described_class.from_params(code:, method_name: "recovery") }

      let(:code) { SecureRandom.hex(16) }

      it { is_expected.to be_valid }

      context "when the code carries spaces" do
        let(:code) { " #{SecureRandom.hex(16)} " }

        it "is valid and normalized" do
          expect(subject).to be_valid
          expect(subject.code).to eq(code.strip)
        end
      end

      context "when the code is not a recovery code" do
        let(:code) { "zzzz-zzzz" }

        it { is_expected.not_to be_valid }
      end
    end
  end
end
