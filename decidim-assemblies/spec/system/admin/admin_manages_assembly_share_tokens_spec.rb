# frozen_string_literal: true

require "spec_helper"

describe "Admin manages assembly share tokens", type: :system do
  let!(:user) { create(:user, :admin, :confirmed, organization: organization) }
  let(:organization) { create(:organization) }
  let!(:assembly) { create(:assembly, organization: organization, private_space: true) }
  let(:participatory_space) { assembly }
  let(:participatory_space_path) { decidim_admin_assemblies.edit_assembly_path(assembly) }

  it_behaves_like "manage participatory space share tokens"

  context "when the user is an assembly admin" do
    let(:user) { create(:user, :confirmed, :admin_terms_accepted, organization: organization) }
    let!(:role) { create(:assembly_user_role, user: user, assembly: assembly, role: :admin) }

    it_behaves_like "manage participatory space share tokens"
  end
end
