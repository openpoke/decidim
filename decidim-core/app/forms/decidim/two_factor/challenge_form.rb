# frozen_string_literal: true

module Decidim
  module TwoFactor
    # The code typed to answer a challenge and the method it belongs to.
    class ChallengeForm < Decidim::Form
      attribute :code, String
      attribute :method_name, String

      def code
        super.to_s.strip
      end

      def method_name
        super.to_s.strip
      end

      def recovery? = false
    end
  end
end
