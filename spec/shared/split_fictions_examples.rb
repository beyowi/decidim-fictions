# frozen_string_literal: true

shared_examples "split fictions" do
  let!(:fictions) { create_list :fiction, 3, component: current_component }
  let!(:target_component) { create :fiction_component, participatory_space: current_component.participatory_space }
  include Decidim::ComponentPathHelper

  context "when selecting fictions" do
    before do
      visit current_path
      page.find("#fictions_bulk.js-check-all").set(true)
    end

    context "when click the bulk action button" do
      before do
        click_button "Actions"
      end

      it "shows the change action option" do
        expect(page).to have_selector(:link_or_button, "Split fictions")
      end
    end

    context "when split into a new one is selected from the actions dropdown" do
      before do
        page.find("#fictions_bulk.js-check-all").set(false)
        page.first(".js-fiction-list-check").set(true)

        click_button "Actions"
        click_button "Split fictions"
      end

      it "shows the component select" do
        expect(page).to have_css("#js-form-split-fictions select", count: 1)
      end

      it "shows an update button" do
        expect(page).to have_css("button#js-submit-split-fictions", count: 1)
      end

      context "when submiting the form" do
        before do
          within "#js-form-split-fictions" do
            select translated(target_component.name), from: :target_component_id_
            page.find("button#js-submit-split-fictions").click
          end
        end

        it "creates a new fiction" do
          expect(page).to have_content("Successfully splitted the fictions into new ones")
          expect(page).to have_css(".table-list tbody tr", count: 2)
        end
      end
    end
  end
end
