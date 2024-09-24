# frozen_string_literal: true

require "spec_helper"

describe "Preview initiative with share token", type: :system do
  let(:organization) { create(:organization) }
  let!(:participatory_space) { create(:initiative, :created, organization: organization) }
  let(:resource_path) { decidim_initiatives.initiative_path(participatory_space) }

  it_behaves_like "preview participatory space with a share_token"
end
