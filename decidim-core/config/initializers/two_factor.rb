# frozen_string_literal: true

module Decidim
  module TwoFactor
    # Redirects logins interrupted by the second factor to the challenge screen.
    class FailureApp < ::RandomStalling
      def respond
        return super unless warden_message == :two_factor_required

        redirect_to decidim.user_two_factor_challenge_path(locale: session[:user_locale] || I18n.locale, redirect_url: request.params["redirect_url"].presence)
      end
    end
  end
end

# Interrupts every sign in until the user proves the second factor; sign_in with
# two_factor: :verified skips the challenge and two_factor: :bypassed trusts the
# provider for users who have not added a factor themselves.
Warden::Manager.after_set_user except: :fetch do |user, warden, options|
  next unless options[:scope] == :user && user.is_a?(Decidim::User)

  # Token sign-ins (the API) keep no session; the token was issued to a session that passed the second factor.
  next if options[:store] == false

  scope = options[:scope]
  session = warden.request.session
  user_params = warden.request.params["user"]
  user_params = {} unless user_params.is_a?(Hash)
  session.delete("decidim_two_factor_bypassed")
  user.expire_weak_password!(user_params["password"])

  next if options[:two_factor] == :verified

  unless user.two_factor_challenge_required?
    session["decidim_two_factor_bypassed"] = user.id if options[:two_factor] == :bypassed
    next
  end

  # Not warden.logout: its callbacks would forget the remember-me tokens of the other devices.
  warden.set_user(nil, scope:, store: false, run_callbacks: false)
  session.delete("warden.user.#{scope}.session")
  warden.session_serializer.delete(scope, user)

  # The codes that ran out keep the login closed until they expire, so the
  # password alone does not buy a new set of attempts.
  throw :warden, scope:, message: :two_factor_exhausted if user.two_factor_challenges.exhausted.exists?(purpose: "login")

  challenge = Decidim::TwoFactor::Challenge.issue_for(user, purpose: "login")
  session["decidim_two_factor_challenge_id"] = challenge.id
  session["decidim_two_factor_remember_me"] = user.respond_to?(:remember_me=) && ActiveModel::Type::Boolean.new.cast(user_params["remember_me"])
  throw :warden, scope:, message: :two_factor_required
end
