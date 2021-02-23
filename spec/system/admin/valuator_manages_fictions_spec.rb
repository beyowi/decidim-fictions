# frozen_string_literal: true

require "spec_helper"

describe "Valuator manages fictions", type: :system do
  let(:manifest_name) { "fictions" }
  let!(:assigned_fiction) { create :fiction, component: current_component }
  let!(:unassigned_fiction) { create :fiction, component: current_component }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
  let(:participatory_space_path) do
    decidim_admin_participatory_processes.edit_participatory_process_path(participatory_process)
  end
  let!(:user) { create :user, organization: organization }
  let!(:valuator_role) { create :participatory_process_user_role, role: :valuator, user: user, participatory_process: participatory_process }
  let!(:another_user) { create :user, organization: organization }
  let!(:another_valuator_role) { create :participatory_process_user_role, role: :valuator, user: another_user, participatory_process: participatory_process }

  include Decidim::ComponentPathHelper

  include_context "when managing a component as an admin"

  before do
    user.update(admin: false)

    create :valuation_assignment, fiction: assigned_fiction, valuator_role: valuator_role
    create :valuation_assignment, fiction: assigned_fiction, valuator_role: another_valuator_role

    visit current_path
  end

  context "when listing the fictions" do
    it "can only see the assigned fictions" do
      expect(page).to have_content(assigned_fiction.title)
      expect(page).to have_no_content(unassigned_fiction.title)
    end
  end

  context "when bulk unassigning valuators" do
    before do
      within find("tr", text: assigned_fiction.title) do
        page.first(".js-fiction-list-check").set(true)
      end

      click_button "Actions"
      click_button "Unassign from valuator"
    end

    it "can unassign themselves" do
      within "#js-form-unassign-fictions-from-valuator" do
        select user.name, from: :valuator_role_id
        page.find("button#js-submit-unassign-fictions-from-valuator").click
      end

      expect(page).to have_content("Valuator unassigned from fictions successfully")
    end

    it "cannot unassign others" do
      within "#js-form-unassign-fictions-from-valuator" do
        select another_user.name, from: :valuator_role_id
        page.find("button#js-submit-unassign-fictions-from-valuator").click
      end

      expect(page).to have_content("You are not authorized to perform this action")
    end
  end

  context "when in the fiction page" do
    before do
      click_link assigned_fiction.title
    end

    it "can only unassign themselves" do
      within "#valuators" do
        expect(page).to have_content(user.name)
        expect(page).to have_content(another_user.name)

        within find("li", text: another_user.name) do
          expect(page).to have_no_selector("a.red-icon")
        end

        within find("li", text: user.name) do
          expect(page).to have_selector("a.red-icon")
          accept_confirm do
            find("a.red-icon").click
          end
        end
      end

      expect(page).to have_content("successfully")
    end

    it "can leave fiction notes" do
      expect(page).to have_content("Private notes")
      within ".add-comment" do
        fill_in "Note", with: " This is my note"
        click_button "Submit"
      end

      within ".comment-thread" do
        expect(page).to have_content("This is my note")
      end
    end

    it "can answer fictions" do
      within "form.edit_fiction_answer" do
        choose "Accepted"
        fill_in_i18n_editor(
          :fiction_answer_answer,
          "#fiction_answer-answer-tabs",
          en: "This is my answer"
        )
        click_button "Answer"
      end
      expect(page).to have_content("successfully")
    end
  end
end
