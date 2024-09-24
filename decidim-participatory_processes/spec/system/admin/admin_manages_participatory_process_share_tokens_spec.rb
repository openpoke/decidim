# frozen_string_literal: true

require "spec_helper"

describe "Admin manages participatory process share tokens", type: :system do
  include_context "when admin administrating a participatory process"
  let(:participatory_space) { participatory_process }
  let(:participatory_space_path) { decidim_admin_participatory_processes.edit_participatory_process_path(participatory_process) }

  it_behaves_like "manage participatory space share tokens"

  context "when the user is a process admin" do
    let(:user) { create(:user, :confirmed, :admin_terms_accepted, organization: organization) }
    let!(:role) { create(:participatory_process_user_role, user: user, participatory_process: participatory_process, role: :admin) }

    it_behaves_like "manage participatory space share tokens"
  end
end
