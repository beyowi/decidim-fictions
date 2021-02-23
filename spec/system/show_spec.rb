# frozen_string_literal: true

require "spec_helper"

describe "show", type: :system do
  include_context "with a component"
  let(:manifest_name) { "fictions" }

  let!(:fiction) { create(:fiction, component: component) }

  before do
    visit_component
    click_link fiction.title[I18n.locale.to_s], class: "card__link"
  end

  context "when shows the fiction component" do
    it "shows the fiction title" do
      expect(page).to have_content fiction.title[I18n.locale.to_s]
    end

    it_behaves_like "going back to list button"
  end
end
