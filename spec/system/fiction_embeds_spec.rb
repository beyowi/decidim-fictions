# frozen_string_literal: true

require "spec_helper"

describe "Fiction embeds", type: :system do
  include_context "with a component"
  let(:manifest_name) { "fictions" }

  let!(:fiction) { create(:fiction, component: component) }

  context "when visiting the embed page for a fiction" do
    before do
      visit resource_locator(fiction).path
      visit "#{current_path}/embed"
    end

    it "renders the page correctly" do
      expect(page).to have_content(fiction.title)
      expect(page).to have_content(organization.name)
    end

    context "when the participatory_space is a process" do
      it "shows the process name" do
        expect(page).to have_i18n_content(participatory_process.title)
      end
    end

    context "when the participatory_space is an assembly" do
      let(:assembly) do
        create(:assembly, organization: organization)
      end
      let(:participatory_space) { assembly }

      it "shows the assembly name" do
        expect(page).to have_i18n_content(assembly.title)
      end
    end
  end
end
