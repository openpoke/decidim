# frozen_string_literal: true

module Decidim
  module TwoFactor
    # Method-picking helpers shared by the screens that answer a challenge.
    module ChallengeMethods
      extend ActiveSupport::Concern
      include FormFactory

      included do
        helper_method :challenge, :challenge_form, :challenge_method_name, :challenge_method, :alternative_methods,
                      :passkey_assertion_options, :challenge_submit_path, :challenge_send_code_path,
                      :challenge_partial_locals
      end

      def send_code
        expired = false

        TwoFactor::SendChallengeCode.call(challenge) do
          on(:ok) { flash[:notice] = t("code_sent", scope: "decidim.two_factor.challenge") }
          on(:throttled) { flash[:alert] = t("code_throttled", scope: "decidim.two_factor.challenge") }
          on(:invalid) { expired = true }
        end

        return handle_expired_challenge if expired

        redirect_to challenge_submit_path("email")
      end

      private

      def verify_challenge(&)
        VerifyChallenge.call(challenge, challenge_form, &)
      end

      def wrong_attempt_message
        t("decidim.two_factor.challenge.#{challenge_method_name}.wrong")
      end

      def challenge_partial_locals
        { submit_path: challenge_submit_path(challenge_method_name), resend_path: challenge_send_code_path }
      end

      def passkey_assertion_options
        @passkey_assertion_options ||= TwoFactor::PasskeyAuthenticator.assertion_options(challenge, request.base_url)
      end

      def challenge_form
        @challenge_form ||= form(challenge_form_class).from_params(params, method_name: challenge_method_name)
      end

      def challenge_form_class
        challenge_method_name == "recovery" ? TwoFactor::RecoveryCodeForm : challenge_method.form_class
      end

      def challenge_method_name
        @challenge_method_name ||= begin
          requested = params[:method_name].to_s.strip

          if requested == "recovery" || attached_names.include?(requested)
            requested
          else
            challenge.method_type
          end
        end
      end

      def challenge_method
        @challenge_method ||= TwoFactor.find_workflow_manifest(challenge_method_name)
      end

      def alternative_methods
        @alternative_methods ||= attached_methods.reject { |manifest| manifest.name == challenge_method_name }
      end

      def attached_methods
        @attached_methods ||= challenge.user.two_factor_attached_methods
      end

      def attached_names
        attached_methods.map(&:name)
      end

      def prepare_challenge
        challenge_authenticator&.prepare_challenge(challenge)
      end

      def challenge_authenticator
        return if challenge_method.blank?

        challenge_method.authenticator_class.find_for(challenge.user, challenge_form)
      end
    end
  end
end
