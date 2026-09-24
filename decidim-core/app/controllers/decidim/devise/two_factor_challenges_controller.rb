# frozen_string_literal: true

module Decidim
  module Devise
    # The screen asking for the second factor between the password and the session.
    class TwoFactorChallengesController < ::DeviseController
      include Decidim::DeviseControllers
      include Decidim::DeviseAuthenticationMethods
      include Decidim::TwoFactor::ChallengeMethods

      before_action :ensure_challenge

      def show
        prepare_challenge
      end

      def create
        verify_challenge do
          on(:ok) { |user| finish_login(user) }

          on(:invalid) do
            flash.now[:alert] = wrong_attempt_message
            render :show, status: :unprocessable_content
          end

          on(:exhausted) { restart_login(t("devise.failure.two_factor_exhausted")) }
          on(:expired) { handle_expired_challenge }
        end
      end

      private

      # Only the session counts here: the remember-me cookie would sign the
      # user in again and send them back to this screen for ever.
      def real_user
        @real_user ||= warden.user(:user)
      end

      def challenge
        return @challenge if defined?(@challenge)

        found = TwoFactor::Challenge.active.find_by(id: session["decidim_two_factor_challenge_id"], purpose: "login")
        @challenge = found && found.user.organization == current_organization && !found.credentials_changed? ? found : nil
      end

      def ensure_challenge
        handle_expired_challenge if challenge.blank?
      end

      def handle_expired_challenge
        restart_login(t("expired", scope: "decidim.devise.two_factor_challenges.show"))
      end

      def challenge_submit_path(method_name)
        user_two_factor_challenge_path(method_name:)
      end

      def challenge_send_code_path
        send_code_user_two_factor_challenge_path
      end

      def finish_login(user)
        return_to = stored_location_for(:user)
        remember_me = session.delete("decidim_two_factor_remember_me")
        reset_session
        user.remember_me = true if remember_me
        sign_in(user, scope: :user, two_factor: :verified)
        store_location_for(:user, return_to)
        store_onboarding_cookie_data!(user)

        flash[:notice] = t("devise.sessions.signed_in")
        redirect_to after_sign_in_path_for(user)
      end

      def restart_login(message)
        session.delete("decidim_two_factor_challenge_id")
        flash[:alert] = message
        redirect_to new_user_session_path
      end
    end
  end
end
