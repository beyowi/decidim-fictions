# frozen_string_literal: true

require "spec_helper"

describe "Fictions in process group home", type: :system do
  include_context "with a component"
  let(:manifest_name) { "fictions" }
  let(:fictions_count) { 2 }
  let(:highlighted_fictions) { fictions_count * 2 }

  let!(:participatory_process_group) do
    create(
      :participatory_process_group,
      participatory_processes: [participatory_process],
      organization: organization,
      name: { en: "Name", ca: "Nom", es: "Nombre" }
    )
  end

  before do
    allow(Decidim::Fictions.config)
      .to receive(:process_group_highlighted_fictions_limit)
      .and_return(highlighted_fictions)
  end

  context "when there are no fictions" do
    it "does not show the highlighted fictions section" do
      visit decidim_participatory_processes.participatory_process_group_path(participatory_process_group)
      expect(page).not_to have_css(".highlighted_fictions")
    end
  end

  context "when there are fictions" do
    let!(:fictions) { create_list(:fiction, fictions_count, component: component) }
    let!(:drafted_fictions) { create_list(:fiction, fictions_count, :draft, component: component) }
    let!(:hidden_fictions) { create_list(:fiction, fictions_count, :hidden, component: component) }
    let!(:withdrawn_fictions) { create_list(:fiction, fictions_count, :withdrawn, component: component) }

    it "shows the highlighted fictions section" do
      visit decidim_participatory_processes.participatory_process_group_path(participatory_process_group)

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
        visit decidim_participatory_processes.participatory_process_group_path(participatory_process_group)

        within ".highlighted_fictions" do
          expect(page).to have_css(".card--fiction", count: highlighted_fictions)

          fictions_titles = fictions.map(&:title)
          highlighted_fictions = page.all(".card--fiction .card__title").map(&:text)
          expect(fictions_titles).to include(*highlighted_fictions)
        end
      end
    end

    context "when scopes enabled and fictions not in top scope" do
      let(:main_scope) { create(:scope, organization: organization) }
      let(:child_scope) { create(:scope, parent: main_scope) }

      before do
        participatory_process.update!(scopes_enabled: true, scope: main_scope)
        fictions.each { |fiction| fiction.update!(scope: child_scope) }
      end

      it "shows a tag with the fictions scope" do
        visit decidim_participatory_processes.participatory_process_group_path(participatory_process_group)

        expect(page).to have_selector(".tags", text: child_scope.name["en"], count: fictions_count)
      end
    end
  end
end
