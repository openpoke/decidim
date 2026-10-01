# frozen_string_literal: true

module Decidim
  module TwoFactor
    # Requires a fresh identity confirmation before the actions that weaken
    # or replace an already enabled second factor.
    module NeedsConfirmation
      extend ActiveSupport::Concern
      include ChallengeMethods

      included do
        before_action :ensure_two_factor_authentication_enabled

        helper_method :password_available?, :password_form, :confirmation_submit_path, :confirmation_submit_method, :confirmation_action
      end

      private

      def ensure_two_factor_authentication_enabled
        redirect_to account_path if !current_organization.two_factor_authentication_enabled? || current_user_impersonated?
      end

      def require_two_factor_confirmation
        return unless current_user.two_factor_enabled?
        return if two_factor_confirmation_window_open?
        return head(:forbidden) unless request.format.html?

        remember_two_factor_pending_action
        return redirect_to(two_factor_authentication_confirmation_path) unless two_factor_confirmation_attempted?

        confirm_two_factor_access { session.delete("decidim_two_factor_pending_action") }
      end

      def confirm_two_factor_access(&block)
        VerifyConfirmation.call(current_user, challenge, challenge_form, password: confirmation_password, password_allowed: password_available?) do
          on(:ok) do
            open_two_factor_confirmation_window
            session.delete("decidim_two_factor_confirmation_challenge_id")
            block.call
          end

          on(:wrong_password) { redirect_to two_factor_authentication_confirmation_path, alert: t("wrong_password", scope: "decidim.two_factor_confirmations.show") }
          on(:invalid) { redirect_to two_factor_authentication_confirmation_path, alert: wrong_attempt_message }
          on(:expired) { handle_expired_challenge }

          on(:exhausted) do
            exhaust_two_factor_confirmation
            redirect_to two_factor_authentication_path
          end
        end
      end

      def confirmation_password
        @confirmation_password ||= form(Decidim::PasswordForm).from_params(params).password.presence
      end

      def password_form
        @password_form ||= form(Decidim::PasswordForm).instance
      end

      def two_factor_confirmation_attempted?
        confirmation_password.present? || params[:method_name].present?
      end

      def remember_two_factor_pending_action
        session["decidim_two_factor_pending_action"] = {
          "method" => request.request_method,
          "path" => request.fullpath,
          "controller" => controller_name,
          "action" => action_name,
          "at" => Time.current.to_i
        }
      end

      def pending_action
        pending = session["decidim_two_factor_pending_action"]
        return unless pending
        return if Time.zone.at(pending["at"]) < Decidim.two_factor_code_expiry_time.ago

        pending
      end

      def confirmation_action
        pending = pending_action
        return unless pending

        "#{pending["controller"]}.#{pending["action"]}"
      end

      # The interrupted POST or DELETE the confirmation form replays; GET actions redirect instead.
      def replayed_action
        pending = pending_action
        pending unless pending.nil? || pending["method"] == "GET"
      end

      def confirmation_submit_path = replayed_action ? replayed_action["path"] : two_factor_authentication_confirmation_path

      def confirmation_submit_method = replayed_action ? replayed_action["method"].downcase.to_sym : :post

      def challenge
        return @challenge if defined?(@challenge)

        found = TwoFactor::Challenge.active.find_by(id: session["decidim_two_factor_confirmation_challenge_id"], purpose: "confirmation", user: current_user)
        @challenge = found || create_challenge
      end

      def create_challenge
        created = TwoFactor::Challenge.issue_for(current_user, purpose: "confirmation")
        session["decidim_two_factor_confirmation_challenge_id"] = created.id
        created
      end

      def challenge_submit_path(method_name)
        two_factor_authentication_confirmation_path(method_name:)
      end

      def challenge_send_code_path
        send_code_two_factor_authentication_confirmation_path
      end

      def challenge_partial_locals
        super.merge(submit_path: confirmation_submit_path, submit_method: confirmation_submit_method)
      end

      def password_available?
        current_organization.sign_in_enabled?
      end

      def handle_expired_challenge
        session.delete("decidim_two_factor_confirmation_challenge_id")
        flash[:alert] = t("expired", scope: "decidim.two_factor_confirmations.show")
        redirect_to two_factor_authentication_confirmation_path
      end

      def exhaust_two_factor_confirmation
        session.delete("decidim_two_factor_confirmation_challenge_id")
        flash[:alert] = t("exhausted", scope: "decidim.two_factor_confirmations.show")
      end

      def two_factor_confirmation_window_open?
        confirmed = session["decidim_two_factor_confirmed"]
        return false unless confirmed.is_a?(Hash) && confirmed["user_id"] == current_user.id

        Time.zone.at(confirmed["at"].to_i) > Decidim.two_factor_confirmation_window.ago
      end

      def open_two_factor_confirmation_window
        session["decidim_two_factor_confirmed"] = { "user_id" => current_user.id, "at" => Time.current.to_i }
      end
    end
  end
end
