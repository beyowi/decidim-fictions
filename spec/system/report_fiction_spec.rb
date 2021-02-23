# frozen_string_literal: true

require "spec_helper"

describe "Report Fiction", type: :system do
  include_context "with a component"

  let(:manifest_name) { "fictions" }
  let!(:fictions) { create_list(:fiction, 3, component: component) }
  let(:reportable) { fictions.first }
  let(:reportable_path) { resource_locator(reportable).path }
  let!(:user) { create :user, :confirmed, organization: organization }

  let!(:component) do
    create(:fiction_component,
           manifest: manifest,
           participatory_space: participatory_process)
  end

  include_examples "reports"
end
