# frozen_string_literal: true

require "spec_helper"

describe "Admin manages conference component share tokens", type: :system do
  include_context "when admin administrating a conference"

  it_behaves_like "manage conference components" do
    let(:participatory_space) { conference }
    let(:participatory_space_engine) { decidim_admin_conferences }
  end
end
