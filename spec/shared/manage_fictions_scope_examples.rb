# frozen_string_literal: true

shared_examples "when managing fictions scope as an admin" do
  context "when in the Fictions list page" do
    it "shows a checkbox to select each fiction" do
      expect(page).to have_css(".table-list tbody .js-fiction-list-check", count: 4)
    end

    it "shows a checkbox to (des)select all fiction" do
      expect(page).to have_css(".table-list thead .js-check-all", count: 1)
    end

    context "when selecting fictions" do
      before do
        page.find("#fictions_bulk.js-check-all").set(true)
      end

      it "shows the number of selected fictions" do
        expect(page).to have_css("span#js-selected-fictions-count", count: 1)
      end

      it "shows the bulk actions button" do
        expect(page).to have_css("#js-bulk-actions-button", count: 1)
      end

      context "when click the bulk action button" do
        before do
          click_button "Actions"
        end

        it "shows the bulk actions dropdown" do
          expect(page).to have_css("#js-bulk-actions-dropdown", count: 1)
        end

        it "shows the change action option" do
          expect(page).to have_selector(:link_or_button, "Change scope")
        end
      end

      context "when change scope is selected from actions dropdown" do
        before do
          click_button "Actions"
          click_button "Change scope"
        end

        it "shows the scope select" do
          expect(page).to have_css("#scope_id.data-picker.picker-single", count: 1)
        end

        it "shows an update button" do
          expect(page).to have_css("button#js-submit-scope-change-fictions", count: 1)
        end
      end
    end
  end
end
