# frozen_string_literal: true

require "spec_helper"

describe "Explore versions", versioning: true, type: :system do
  include_context "with a component"
  let(:component) { create(:fiction_component, organization: organization) }
  let!(:fiction) { create(:fiction, body: "One liner body", component: component) }
  let!(:emendation) { create(:fiction, body: "Amended One liner body", component: component) }
  let!(:amendment) { create :amendment, amendable: fiction, emendation: emendation }

  let(:form) do
    Decidim::Amendable::ReviewForm.from_params(
      id: amendment.id,
      amendable_gid: fiction.to_sgid.to_s,
      emendation_gid: emendation.to_sgid.to_s,
      emendation_params: { title: emendation.title, body: emendation.body }
    )
  end
  let(:command) { Decidim::Amendable::Accept.new(form) }

  let(:fiction_path) { Decidim::ResourceLocatorPresenter.new(fiction).path }

  context "when visiting a fiction details" do
    before do
      visit fiction_path
    end

    it "has only one version" do
      expect(page).to have_content("Version number 1 (of 1)")
    end

    it "shows the versions index" do
      expect(page).to have_link "see other versions"
    end

    context "when accepting an amendment" do
      before do
        command.call
        visit fiction_path
      end

      it "creates a new version" do
        expect(page).to have_content("Version number 2 (of 2)")
      end
    end
  end

  context "when visiting versions index" do
    before do
      visit fiction_path
      command.call
      click_link "see other versions"
    end

    it "lists all versions" do
      expect(page).to have_link("Version 1")
      expect(page).to have_link("Version 2")
    end

    it "shows the versions count" do
      expect(page).to have_content("VERSIONS\n2")
    end

    it "allows going back to the fiction" do
      click_link "Go back to fiction"
      expect(page).to have_current_path fiction_path
    end

    it "shows the creation date" do
      within ".card--list__item:last-child" do
        expect(page).to have_content(Time.zone.today.strftime("%d/%m/%Y"))
      end
    end
  end

  context "when showing version" do
    before do
      visit fiction_path
      command.call
      click_link "see other versions"

      within ".card--list__item:last-child" do
        click_link("Version 2")
      end
    end

    it "shows the version number" do
      expect(page).to have_content("VERSION NUMBER\n2 out of 2")
    end

    it "allows going back to the fiction" do
      click_link "Go back to fiction"
      expect(page).to have_current_path fiction_path
    end

    it "allows going back to the versions list" do
      click_link "Show all versions"
      expect(page).to have_current_path fiction_path + "/versions"
    end

    it "shows the creation date" do
      within ".card.extra.definition-data" do
        expect(page).to have_content(Time.zone.today.strftime("%d/%m/%Y"))
      end
    end

    it "shows the changed attributes" do
      expect(page).to have_content("Changes at")

      within ".diff-for-title" do
        expect(page).to have_content("TITLE")

        within ".diff > ul > .del" do
          expect(page).to have_content(fiction.title)
        end

        within ".diff > ul > .ins" do
          expect(page).to have_content(emendation.title)
        end
      end

      within ".diff-for-body" do
        expect(page).to have_content("BODY")

        within ".diff > ul > .del" do
          expect(page).to have_content(fiction.body)
        end

        within ".diff > ul > .ins" do
          expect(page).to have_content(emendation.body)
        end
      end
    end
  end
end
