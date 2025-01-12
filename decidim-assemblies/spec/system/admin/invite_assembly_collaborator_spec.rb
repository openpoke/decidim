# frozen_string_literal: true

require "spec_helper"

require "decidim/admin/test/invite_participatory_space_collaborators_shared_examples"

describe "Invite assembly collaborator" do
  let(:participatory_space) { create(:assembly) }
  let(:space_sidebar_label) { "Assemblies" }
  let(:role) { "Collaborator" }
  let(:participatory_space_user_roles_path) { decidim_admin_assemblies.assembly_user_roles_path(participatory_space) }
  let(:new_button_label) { "New assembly admin" }

  include_context "when inviting participatory space users"

  it_behaves_like "inviting participatory space collaborators"
end
