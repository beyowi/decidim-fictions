# frozen_string_literal: true

require "spec_helper"

describe "Index fictions", type: :system do
  include_context "with a component"
  let(:manifest_name) { "fictions" }

  context "when there are fictions" do
    let!(:fictions) { create_list(:fiction, 3, component: component) }

    it "doesn't display empty message" do
      visit_component

      expect(page).to have_no_content("There is no fiction yet")
    end
  end

  context "when there are no fictions" do
    context "when there are no filters" do
      it "shows generic empty message" do
        visit_component

        expect(page).to have_content("There is no fiction yet")
      end
    end

    context "when there are filters" do
      let!(:fictions) { create(:fiction, :with_answer, :accepted, component: component) }

      it "shows filters empty message" do
        visit_component

        uncheck "Accepted"

        expect(page).to have_content("There isn't any fiction with this criteria")
      end
    end
  end
end
