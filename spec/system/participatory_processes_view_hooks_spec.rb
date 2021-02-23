# frozen_string_literal: true

require "spec_helper"

describe "Fictions in process home", type: :system do
  include_context "with a component"
  let(:manifest_name) { "fictions" }
  let(:fictions_count) { 2 }
  let(:highlighted_fictions) { fictions_count * 2 }

  before do
    allow(Decidim::Fictions.config)
      .to receive(:participatory_space_highlighted_fictions_limit)
      .and_return(highlighted_fictions)
  end

  context "when there are no fictions" do
    it "does not show the highlighted fictions section" do
      visit resource_locator(participatory_process).path
      expect(page).not_to have_css(".highlighted_fictions")
    end
  end

  context "when there are fictions" do
    let!(:fictions) { create_list(:fiction, fictions_count, component: component) }
    let!(:drafted_fictions) { create_list(:fiction, fictions_count, :draft, component: component) }
    let!(:hidden_fictions) { create_list(:fiction, fictions_count, :hidden, component: component) }
    let!(:withdrawn_fictions) { create_list(:fiction, fictions_count, :withdrawn, component: component) }

    it "shows the highlighted fictions section" do
      visit resource_locator(participatory_process).path

      within ".highlighted_fictions" do
        expect(page).to have_css(".card--fiction", count: fictions_count)

        fictions_titles = fictions.map(&:title)
        drafted_fictions_titles = drafted_fictions.map(&:title)
        hidden_fictions_titles = hidden_fictions.map(&:title)
        withdrawn_fictions_titles = withdrawn_fictions.map(&:title)

        highlighted_fictions = page.all(".card--fiction .card__title").map(&:text)
        expect(fictions_titles).to include(*highlighted_fictions)
        expect(drafted_fictions_titles).not_to include(*highlighted_fictions)
        expect(hidden_fictions_titles).not_to include(*highlighted_fictions)
        expect(withdrawn_fictions_titles).not_to include(*highlighted_fictions)
      end
    end

    context "and there are more fictions than those that can be shown" do
      let!(:fictions) { create_list(:fiction, highlighted_fictions + 2, component: component) }

      it "shows the amount of fictions configured" do
        visit resource_locator(participatory_process).path

        within ".highlighted_fictions" do
          expect(page).to have_css(".card--fiction", count: highlighted_fictions)

          fictions_titles = fictions.map(&:title)
          highlighted_fictions = page.all(".card--fiction .card__title").map(&:text)
          expect(fictions_titles).to include(*highlighted_fictions)
        end
      end
    end
  end
end
