# frozen_string_literal: true

require "spec_helper"

describe "Edit fictions", type: :system do
  include_context "with a component"
  let(:manifest_name) { "fictions" }

  let!(:user) { create :user, :confirmed, organization: participatory_process.organization }
  let!(:another_user) { create :user, :confirmed, organization: participatory_process.organization }
  let!(:fiction) { create :fiction, users: [user], component: component }

  before do
    switch_to_host user.organization.host
  end

  describe "editing my own fiction" do
    let(:new_title) { "This is my fiction new title" }
    let(:new_body) { "This is my fiction new body" }

    before do
      login_as user, scope: :user
    end

    it "can be updated" do
      visit_component

      click_link fiction.title
      click_link "Edit fiction"

      expect(page).to have_content "EDIT FICTION"

      within "form.edit_fiction" do
        fill_in :fiction_title, with: new_title
        fill_in :fiction_body, with: new_body
        click_button "Send"
      end

      expect(page).to have_content(new_title)
      expect(page).to have_content(new_body)
    end

    context "when updating with wrong data" do
      let(:component) { create(:fiction_component, :with_creation_enabled, :with_attachments_allowed, participatory_space: participatory_process) }

      it "returns an error message" do
        visit_component

        click_link fiction.title
        click_link "Edit fiction"

        expect(page).to have_content "EDIT FICTION"

        within "form.edit_fiction" do
          fill_in :fiction_body, with: "A"
          click_button "Send"
        end

        expect(page).to have_content("is too short (under 15 characters)", count: 2)

        within "form.edit_fiction" do
          fill_in :fiction_body, with: "WE DO NOT WANT TO SHOUT IN THE FICTION BODY TEXT!"
          click_button "Send"
        end

        expect(page).to have_content("is using too many capital letters (over 25% of the text)")
      end

      it "keeps the submitted values" do
        visit_component

        click_link fiction.title
        click_link "Edit fiction"

        expect(page).to have_content "EDIT FICTION"

        within "form.edit_fiction" do
          fill_in :fiction_title, with: "A title with a #hashtag"
          fill_in :fiction_body, with: "ỲÓÜ WÄNTt TÙ ÚPDÀTÉ À PRÖPÔSÁL"
        end
        click_button "Send"

        expect(page).to have_selector("input[value='A title with a #hashtag']")
        expect(page).to have_content("ỲÓÜ WÄNTt TÙ ÚPDÀTÉ À PRÖPÔSÁL")
      end
    end
  end

  describe "editing someone else's fiction" do
    before do
      login_as another_user, scope: :user
    end

    it "renders an error" do
      visit_component

      click_link fiction.title
      expect(page).to have_no_content("Edit fiction")
      visit current_path + "/edit"

      expect(page).to have_content("not authorized")
    end
  end

  describe "editing my fiction outside the time limit" do
    let!(:fiction) { create :fiction, users: [user], component: component, created_at: 1.hour.ago }

    before do
      login_as another_user, scope: :user
    end

    it "renders an error" do
      visit_component

      click_link fiction.title
      expect(page).to have_no_content("Edit fiction")
      visit current_path + "/edit"

      expect(page).to have_content("not authorized")
    end
  end
end
