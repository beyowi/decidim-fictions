# frozen_string_literal: true

shared_examples "merge fictions" do
  let!(:fictions) { create_list :fiction, 3, :official, component: current_component }
  let!(:target_component) { create :fiction_component, participatory_space: current_component.participatory_space }
  include Decidim::ComponentPathHelper

  before do
    Decidim::Fictions::Fiction.where.not(id: fictions.map(&:id)).destroy_all
  end

  context "when selecting fictions" do
    before do
      visit current_path
      page.find("#fictions_bulk.js-check-all").set(true)
    end

    context "when click the bulk action button" do
      it "shows the change action option" do
        click_button "Actions"

        expect(page).to have_selector(:link_or_button, "Merge into a new one")
      end

      context "when only one fiction is checked" do
        before do
          page.find("#fictions_bulk.js-check-all").set(false)
          page.first(".js-fiction-list-check").set(true)
        end

        it "does not show the merge action option" do
          click_button "Actions"

          expect(page).to have_no_selector(:link_or_button, "Merge into a new one")
        end
      end
    end

    context "when merge into a new one is selected from the actions dropdown" do
      before do
        click_button "Actions"
        click_button "Merge into a new one"
      end

      it "shows the component select" do
        expect(page).to have_css("#js-form-merge-fictions select", count: 1)
      end

      it "shows an update button" do
        expect(page).to have_css("button#js-submit-merge-fictions", count: 1)
      end

      context "when submiting the form" do
        before do
          within "#js-form-merge-fictions" do
            select translated(target_component.name), from: :target_component_id_
            page.find("button#js-submit-merge-fictions").click
          end
        end

        it "creates a new fiction" do
          expect(page).to have_content("Successfully merged the fictions into a new one")
          expect(page).to have_css(".table-list tbody tr", count: 1)
          expect(page).to have_current_path(manage_component_path(target_component))
        end

        context "when merging to the same component" do
          let!(:target_component) { current_component }
          let!(:fiction_ids) { fictions.map(&:id) }

          it "creates a new fiction and deletes the other ones" do
            expect(page).to have_content("Successfully merged the fictions into a new one")
            expect(page).to have_css(".table-list tbody tr", count: 1)
            expect(page).to have_current_path(manage_component_path(current_component))

            fiction_ids.each do |id|
              expect(page).not_to have_xpath("//tr[@data-id='#{id}']")
            end
          end
        end
      end
    end
  end
end
