# frozen_string_literal: true

require "spec_helper"

module Decidim
  module System
    describe UpdateOrganization do
      describe "call" do
        let(:form) do
          UpdateOrganizationForm.new(params)
        end
        let(:organization) { create(:organization, name: { en: "My organization" }) }

        let(:command) { described_class.new(organization.id, form) }

        context "when the form is valid" do
          let(:from_label) { "Decide Gotham" }
          let(:two_factor_authentication_enabled) { true }
          let(:two_factor_enforced_for) { "admins" }
          let(:two_factor_grace_period_days) { 10 }
          let(:params) do
            {
              name: { en: "Gotham City" },
              short_name: { en: "GothamCity" },
              host: "decide.example.org",
              secondary_hosts: "foo.example.org\r\n\r\nbar.example.org",
              force_users_to_authenticate_before_access_organization: false,
              users_registration_mode: "existing",
              two_factor_authentication_enabled:,
              two_factor_enforced_for:,
              available_two_factor_methods: %w(totp email),
              two_factor_grace_period_days:,
              **smtp_settings,
              **omniauth_settings,
              file_upload_settings: params_for_uploads(upload_settings)
            }
          end
          let(:upload_settings) do
            Decidim::OrganizationSettings.default(:upload)
          end
          let(:omniauth_settings) do
            {
              "omniauth_settings_facebook_enabled" => true,
              "omniauth_settings_facebook_app_id" => "facebook-app-id",
              "omniauth_settings_facebook_app_secret" => "facebook-app-secret"
            }
          end
          let(:smtp_settings) do
            {
              "address" => "mail.example.org",
              "port" => "25",
              "user_name" => "f.laguardia",
              "password" => Decidim::AttributeEncryptor.encrypt("password"),
              "from_email" => "decide@example.org",
              "from_label" => from_label
            }
          end

          it "returns a valid response" do
            expect { command.call }.to broadcast(:ok)
          end

          it "updates the organization" do
            expect { command.call }.to change(Organization, :count).by(1)
            organization = Organization.last

            expect(translated(organization.name)).to eq("Gotham City")
            expect(translated(organization.short_name)).to eq("GothamCity")
            expect(organization.host).to eq("decide.example.org")
            expect(organization.secondary_hosts).to contain_exactly("foo.example.org", "bar.example.org")
            expect(organization.users_registration_mode).to eq("existing")
            expect(organization.smtp_settings["from"]).to eq("Decide Gotham <decide@example.org>")
            expect(organization.smtp_settings["from_email"]).to eq("decide@example.org")
            expect(organization.omniauth_settings["omniauth_settings_facebook_enabled"]).to be(true)
            expect(organization.file_upload_settings).to eq(upload_settings)
            expect(
              Decidim::AttributeEncryptor.decrypt(organization.omniauth_settings["omniauth_settings_facebook_app_id"])
            ).to eq("facebook-app-id")
            expect(
              Decidim::AttributeEncryptor.decrypt(organization.omniauth_settings["omniauth_settings_facebook_app_secret"])
            ).to eq("facebook-app-secret")
          end

          it "saves the two-factor settings" do
            command.call
            organization.reload

            expect(organization.two_factor_enforced_for).to eq("admins")
            expect(organization.available_two_factor_methods).to eq(%w(totp email))
            expect(organization.two_factor_grace_period_days).to eq(10)
          end

          it "stamps the enforcement date when the enforcement starts" do
            expect { command.call }.to change { organization.reload.two_factor_enforced_at }.from(nil)
          end

          context "when the enforcement was already on" do
            let(:enforced_at) { 10.days.ago }

            before { organization.update!(two_factor_enforced_for: "all", two_factor_enforced_at: enforced_at) }

            it "keeps the original enforcement date" do
              command.call

              expect(organization.reload.two_factor_enforced_at).to be_within(1.second).of(enforced_at)
            end
          end

          context "when the enforcement scope widens" do
            let(:two_factor_enforced_for) { "all" }

            before { organization.update!(two_factor_enforced_for: "admins", two_factor_enforced_at: 10.days.ago) }

            it "restamps the enforcement date" do
              command.call

              expect(organization.reload.two_factor_enforced_at).to be_within(1.minute).of(Time.current)
            end
          end

          context "when the enforcement is switched off" do
            let(:two_factor_enforced_for) { "none" }

            before { organization.update!(two_factor_enforced_for: "admins", two_factor_enforced_at: Time.current) }

            it "clears the enforcement date" do
              command.call

              expect(organization.reload.two_factor_enforced_at).to be_nil
            end
          end

          context "when two-factor authentication is switched off with the scope untouched" do
            let(:two_factor_authentication_enabled) { false }

            before { organization.update!(two_factor_authentication_enabled: true, two_factor_enforced_for: "admins", two_factor_enforced_at: Time.current) }

            it "clears the enforcement date" do
              command.call

              expect(organization.reload.two_factor_enforced_at).to be_nil
            end
          end

          describe "encrypted smtp settings" do
            context "when from_label is empty" do
              let(:from_label) { "" }

              it "sets the label from email" do
                command.call
                organization = Organization.last

                expect(organization.smtp_settings["from"]).to eq("decide@example.org")
                expect(organization.smtp_settings["from_email"]).to eq("decide@example.org")
              end
            end

            context "when all smtp settings are blank" do
              let(:smtp_settings) do
                {
                  "address" => "",
                  "port" => "",
                  "user_name" => "",
                  "password" => "",
                  "from_email" => "",
                  "from_label" => ""
                }
              end

              it "sets smtp_settings to nil" do
                command.call
                organization = Organization.last

                expect(translated(organization.name)).to eq("Gotham City")
                expect(organization.smtp_settings).to be_nil
              end
            end
          end

          context "when all omniauth settings are blank" do
            let(:omniauth_settings) do
              {
                "omniauth_settings_facebook_enabled" => nil,
                "omniauth_settings_facebook_app_id" => nil,
                "omniauth_settings_facebook_app_secret" => nil
              }
            end

            it "sets omniauth_settings to nil" do
              command.call
              organization = Organization.last

              expect(translated(organization.name)).to eq("Gotham City")
              expect(organization.omniauth_settings).to be_nil
            end
          end
        end

        describe "when header snippets are configured" do
          let(:params) do
            {
              name: { en: "Gotham City" },
              short_name: { en: "GothamCity" },
              host: "decide.example.org",
              users_registration_mode: "existing",
              two_factor_enforced_for: "none",
              available_two_factor_methods: %w(totp email),
              file_upload_settings: params_for_uploads(upload_settings),
              header_snippets: "<script>alert('Hello world')</script>"
            }
          end
          let(:upload_settings) do
            Decidim::OrganizationSettings.default(:upload)
          end

          before do
            allow(Decidim).to receive(:enable_html_header_snippets).and_return(true)
          end

          it "saves header snippets" do
            expect { command.call }.to broadcast(:ok)
            organization.reload

            expect(organization.header_snippets).to be_present
            expect(organization.header_snippets).to eq("<script>alert('Hello world')</script>")
          end
        end

        context "when the form is invalid" do
          context "and the name is empty" do
            let(:params) do
              {
                name: { en: "" },
                host: "foo.com"
              }
            end

            it "returns an invalid response" do
              expect { command.call }.to broadcast(:invalid)
            end
          end

          context "and the name is empty hash" do
            let(:params) do
              {
                name: {},
                host: "foo.com"
              }
            end

            it "returns an invalid response" do
              expect { command.call }.to broadcast(:invalid)
            end
          end

          context "and the name is nil" do
            let(:params) do
              {
                name: nil,
                host: "foo.com"
              }
            end

            it "returns an invalid response" do
              expect { command.call }.to broadcast(:invalid)
            end
          end
        end

        private

        def params_for_uploads(hash)
          hash.to_h do |key, value|
            case value
            when Hash
              value = params_for_uploads(value)
            when Array
              value = value.join(",")
            end

            [key, value]
          end
        end
      end
    end
  end
end
