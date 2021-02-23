# frozen_string_literal: true

require "spec_helper"

describe "Admin edits fictions", type: :system do
  let(:manifest_name) { "fictions" }
  let(:organization) { participatory_process.organization }
  let!(:user) { create :user, :admin, :confirmed, organization: organization }
  let!(:fiction) { create :fiction, :official, component: component }
  let(:creation_enabled?) { true }

  include_context "when managing a component as an admin"

  before do
    component.update!(
      step_settings: {
        component.participatory_space.active_step.id => {
          creation_enabled: creation_enabled?
        }
      }
    )
  end

  describe "editing an official fiction" do
    let(:new_title) { "This is my fiction new title" }
    let(:new_body) { "This is my fiction new body" }

    it "can be updated" do
      visit_component_admin

      find("a.action-icon--edit-fiction").click
      expect(page).to have_content "Update fiction"

      fill_in "Title", with: new_title
      fill_in_editor :fiction_body, with: new_body
      click_button "Update"

      preview_window = window_opened_by { find("a.action-icon--preview").click }

      within_window preview_window do
        expect(page).to have_content(new_title)
        expect(page).to have_content(new_body)
      end
    end

    context "when the fiction has some votes" do
      before do
        create :fiction_vote, fiction: fiction
      end

      it "doesn't let the user edit it" do
        visit_component_admin

        expect(page).to have_content(fiction.title)
        expect(page).to have_no_css("a.action-icon--edit-fiction")
        visit current_path + "fictions/#{fiction.id}/edit"

        expect(page).to have_content("not authorized")
      end
    end
  end

  describe "editing a non-official fiction" do
    let!(:fiction) { create :fiction, users: [user], component: component }

    it "renders an error" do
      visit_component_admin

      expect(page).to have_content(fiction.title)
      expect(page).to have_no_css("a.action-icon--edit-fiction")
      visit current_path + "fictions/#{fiction.id}/edit"

      expect(page).to have_content("not authorized")
    end
  end
end
