# frozen_string_literal: true

Decidim::TwoFactor.register_workflow(:totp) do |two_factor_method|
  two_factor_method.authenticator_class_name = "Decidim::TwoFactor::TotpAuthenticator"
  two_factor_method.icon = "smartphone-line"
end

Decidim::TwoFactor.register_workflow(:email) do |two_factor_method|
  two_factor_method.authenticator_class_name = "Decidim::TwoFactor::EmailAuthenticator"
  two_factor_method.icon = "mail-line"
end

Decidim::TwoFactor.register_workflow(:passkey) do |two_factor_method|
  two_factor_method.authenticator_class_name = "Decidim::TwoFactor::PasskeyAuthenticator"
  two_factor_method.form_class_name = "Decidim::TwoFactor::PasskeyChallengeForm"
  two_factor_method.icon = "fingerprint-line"
end
