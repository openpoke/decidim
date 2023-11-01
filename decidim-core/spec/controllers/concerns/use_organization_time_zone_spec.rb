# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe ApplicationController, type: :controller do
    let(:utc_time_zone) { "UTC" }
    let(:alt_time_zone) { "Hawaii" }
    let(:organization) { create(:organization, time_zone: time_zone) }
    let(:user) { create :user, :confirmed, organization: organization, time_zone: user_time_zone }
    let(:user_time_zone) { "" }

    before do
      request.env["decidim.current_organization"] = organization
      allow(controller).to receive(:current_user) { user }
    end

    context "when time zone is UTC" do
      let(:time_zone) { utc_time_zone }

      it "controller uses UTC" do
        expect(controller.organization_time_zone).to eq(utc_time_zone)
      end

      it "Time uses UTC zone within the controller scope" do
        controller.use_organization_time_zone do
          expect(Time.zone.name).to eq(utc_time_zone)
        end
      end

      it "Time uses UTC outside the controller scope" do
        expect(Time.zone.name).to eq(utc_time_zone)
      end
    end

    context "when time zone is non-UTC" do
      let(:time_zone) { alt_time_zone }

      it "controller uses the custom time zone" do
        expect(controller.organization_time_zone).to eq(alt_time_zone)
      end

      it "Time uses configured time zone within the controller scope" do
        controller.use_organization_time_zone do
          expect(Time.zone.name).to eq(alt_time_zone)
        end
      end

      it "Time uses UTC outside the controller scope" do
        expect(Time.zone.name).to eq(utc_time_zone)
      end
    end

    context "when Rails is non-UTC", tz: "Azores" do
      context "and organizations uses UTC" do
        let(:time_zone) { utc_time_zone }

        it "controller uses UTC" do
          expect(controller.organization_time_zone).to eq(utc_time_zone)
        end

        it "Time uses UTC zone within the controller scope" do
          controller.use_organization_time_zone do
            expect(Time.zone.name).to eq(utc_time_zone)
          end
        end

        it "Time uses Rails timezone outside the controller scope" do
          expect(Time.zone.name).to eq("Azores")
        end
      end

      context "and organizations uses non-UTC" do
        let(:time_zone) { alt_time_zone }

        it "controller uses UTC" do
          expect(controller.organization_time_zone).to eq(alt_time_zone)
        end

        it "Time uses UTC zone within the controller scope" do
          controller.use_organization_time_zone do
            expect(Time.zone.name).to eq(alt_time_zone)
          end
        end

        it "Time uses Rails timezone outside the controller scope" do
          expect(Time.zone.name).to eq("Azores")
        end
      end
    end

    context "when time zone is defined by the user" do
      let(:time_zone) { utc_time_zone }
      let(:user_time_zone) { "London" }

      it "controller uses London" do
        expect(controller.organization_time_zone).to eq("London")
      end

      it "Time uses UTC zone within the controller scope" do
        controller.use_organization_time_zone do
          expect(Time.zone.name).to eq("London")
        end
      end

      it "Time uses Rails timezone outside the controller scope" do
        expect(Time.zone.name).to eq("UTC")
      end
    end

    context "when user's time zone in not present" do
      let(:time_zone) { utc_time_zone }
      let(:user_time_zone) { "" }

      it "controller uses time zone of organization" do
        expect(controller.organization_time_zone).to eq(utc_time_zone)
      end
    end

    context "when user is not present" do
      let(:time_zone) { utc_time_zone }
      let(:user) { nil }

      it "controller uses time zone of organization" do
        expect(controller.organization_time_zone).to eq(utc_time_zone)
      end
    end
  end
end
