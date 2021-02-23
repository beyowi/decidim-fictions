# frozen_string_literal: true

require "spec_helper"

describe "Admin manages fictions", type: :system do
  let(:manifest_name) { "fictions" }
  let!(:fiction) { create :fiction, component: current_component }
  let!(:reportables) { create_list(:fiction, 3, component: current_component) }
  let(:participatory_space_path) do
    decidim_admin_participatory_processes.edit_participatory_process_path(participatory_process)
  end

  include_context "when managing a component as an admin"

  it_behaves_like "manage fictions"
  it_behaves_like "view fiction details from admin"
  it_behaves_like "manage moderations"
  it_behaves_like "export fictions"
  it_behaves_like "manage announcements"
  it_behaves_like "manage fictions help texts"
  it_behaves_like "manage fiction wizard steps help texts"
  it_behaves_like "when managing fictions category as an admin"
  it_behaves_like "when managing fictions scope as an admin"
  it_behaves_like "import fictions"
  it_behaves_like "manage fictions permissions"
  it_behaves_like "merge fictions"
  it_behaves_like "split fictions"
  it_behaves_like "filter fictions"
  it_behaves_like "publish answers"
end
