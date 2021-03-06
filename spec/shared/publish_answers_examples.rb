# frozen_string_literal: true

shared_examples "publish answers" do
  context "when publishing answers at once" do
    before do
      create_list :fiction, 3, :accepted_not_published, component: current_component

      visit current_path
    end

    it "publishes some answers" do
      page.find("#fictions_bulk.js-check-all").set(true)
      page.first("[data-published-state=false] .js-fiction-list-check").set(false)

      click_button "Actions"
      click_button "Publish answers"

      within "#js-publish-answers-actions" do
        expect(page).to have_content("Answers for 2 fictions will be published.")
      end

      perform_enqueued_jobs do
        page.find("button#js-submit-publish-answers").click

        visit current_path

        # run publish answers job

        visit current_path
      end

      expect(page).to have_content("Accepted", count: 3)
      expect(page).to have_content("Not answered (Accepted)", count: 1)
    end

    it "can't publish answers for non answered fictions" do
      page.find("#fictions_bulk.js-check-all").set(true)
      page.all("[data-published-state=false] .js-fiction-list-check").each { |c| c.set(false); }

      click_button "Actions"
      expect(page).not_to have_content("Publish answers")
    end
  end
end
