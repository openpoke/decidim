# frozen_string_literal: true

require "spec_helper"

module Decidim::Admin
  describe HideResource do
    let(:reportable) { create(:dummy_resource) }
    let(:moderation) { create(:moderation, reportable: reportable, report_count: 1) }
    let!(:report) { create(:report, moderation: moderation) }
    let(:current_user) { create :user, organization: reportable.participatory_space.organization }
    let(:command) { described_class.new(reportable, current_user) }
    let(:author_notification) do
      {
        event: "decidim.events.reports.resource_hidden",
        event_class: Decidim::ResourceHiddenEvent,
        resource: reportable,
        extra: {
          report_reasons: [report.reason]
        },
        affected_users: reportable.try(:authors) || [reportable.try(:author)]
      }
    end

    context "when everything is ok" do
      it "broadcasts ok" do
        expect { command.call }.to broadcast(:ok)
      end

      it "hides the resource" do
        command.call
        expect(reportable.reload).to be_hidden
      end

      it "traces the action", versioning: true do
        expect(Decidim.traceability)
          .to receive(:perform_action!)
          .with("hide", moderation, current_user, extra: { reportable_type: "Decidim::DummyResources::DummyResource" })
          .and_call_original

        expect { command.call }.to change(Decidim::ActionLog, :count)

        action_log = Decidim::ActionLog.last
        expect(action_log.version).to be_present
        expect(action_log.version.event).to eq "update"
      end

      it "sends a notification to the reportable's author" do
        expect(Decidim::EventsManager).to receive(:publish).with(author_notification)
        command.call
      end
    end

    context "when the resource is already hidden" do
      let(:moderation) { create(:moderation, reportable: reportable, report_count: 1, hidden_at: Time.current) }
      let(:authors) { reportable.try(:authors) || [reportable.try(:author)] }
      let(:reasons) { reportable.moderation.reports.pluck(:reason).uniq }

      it "broadcasts invalid" do
        expect { command.call }.to broadcast(:invalid)
      end

      it "sends email to author" do
        Decidim::Admin::HiddenResourceMailer.notify_mail(reportable, authors, reasons).deliver_now

        expect(last_email.subject).to eq(I18n.t("decidim.admin.hidden_resource_mailer.notify_mail.subject"))
        expect(last_email.to).to eq(authors.pluck(:email).uniq)
      end
    end

    context "when the resource is not reported" do
      let(:moderation) { nil }
      let!(:report) { nil }

      it "broadcasts invalid" do
        expect { command.call }.to broadcast(:invalid)
      end
    end
  end
end
