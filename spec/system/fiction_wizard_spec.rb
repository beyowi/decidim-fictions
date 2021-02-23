# frozen_string_literal: true

require "spec_helper"

describe "Fiction", type: :system do
  include_context "with a component"
  let(:manifest_name) { "fictions" }
  let(:organization) { create :organization }

  let!(:category) { create :category, participatory_space: participatory_process }
  let!(:scope) { create :scope, organization: organization }
  let!(:user) { create :user, :confirmed, organization: organization }
  let(:scoped_participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: scope) }

  let(:address) { "Plaça Santa Jaume, 1, 08002 Barcelona" }
  let(:latitude) { 41.3825 }
  let(:longitude) { 2.1772 }

  let(:fiction_title) { "More sidewalks and less roads" }
  let(:fiction_body) { "Cities need more people, not more cars" }

  let!(:component) do
    create(:fiction_component,
           :with_creation_enabled,
           manifest: manifest,
           participatory_space: participatory_process)
  end
  let(:component_path) { Decidim::EngineRouter.main_proxy(component) }

  context "when creating a new fiction" do
    before do
      login_as user, scope: :user
      visit_component
      click_link "New fiction"
    end

    context "when in step_1: Create your fiction" do
      it "show current step_1 highlighted" do
        within ".wizard__steps" do
          expect(page).to have_css(".step--active", count: 1)
          expect(page).to have_css(".step--past", count: 0)
          expect(page).to have_css(".step--active.step_1")
        end
      end

      it "fill in title and body" do
        within ".card__content form" do
          fill_in :fiction_title, with: fiction_title
          fill_in :fiction_body, with: fiction_body
          find("*[type=submit]").click
        end
      end

      context "when the back button is clicked" do
        before do
          click_link "Back"
        end

        it "redirects to fictions_path" do
          expect(page).to have_content("FICTIONS")
          expect(page).to have_content("New fiction")
        end
      end
    end

    context "when in step_2: Compare" do
      context "with similar results" do
        before do
          create(:fiction, title: "More sidewalks and less roads", body: "Cities need more people, not more cars", component: component)
          create(:fiction, title: "More sidewalks and less roadways", body: "Green is always better", component: component)
          visit_component
          click_link "New fiction"
          within ".new_fiction" do
            fill_in :fiction_title, with: fiction_title
            fill_in :fiction_body, with: fiction_body

            find("*[type=submit]").click
          end
        end

        it "show previous and current step_2 highlighted" do
          within ".wizard__steps" do
            expect(page).to have_css(".step--active", count: 1)
            expect(page).to have_css(".step--past", count: 1)
            expect(page).to have_css(".step--active.step_2")
          end
        end

        it "shows similar fictions" do
          expect(page).to have_content("SIMILAR FICTIONS (2)")
          expect(page).to have_css(".card--fiction", text: "More sidewalks and less roads")
          expect(page).to have_css(".card--fiction", count: 2)
        end

        it "show continue button" do
          expect(page).to have_link("Continue")
        end

        it "does not show the back button" do
          expect(page).not_to have_link("Back")
        end
      end

      context "without similar results" do
        before do
          visit_component
          click_link "New fiction"
          within ".new_fiction" do
            fill_in :fiction_title, with: fiction_title
            fill_in :fiction_body, with: fiction_body

            find("*[type=submit]").click
          end
        end

        it "redirects to step_3: complete" do
          within ".section-heading" do
            expect(page).to have_content("COMPLETE YOUR FICTION")
          end
          expect(page).to have_css(".edit_fiction")
        end

        it "shows no similar fiction found callout" do
          within ".flash.callout.success" do
            expect(page).to have_content("Well done! No similar fictions found")
          end
        end
      end
    end

    context "when in step_3: Complete" do
      before do
        visit_component
        click_link "New fiction"
        within ".new_fiction" do
          fill_in :fiction_title, with: fiction_title
          fill_in :fiction_body, with: fiction_body

          find("*[type=submit]").click
        end
      end

      it "show previous and current step_3 highlighted" do
        within ".wizard__steps" do
          expect(page).to have_css(".step--active", count: 1)
          expect(page).to have_css(".step--past", count: 2)
          expect(page).to have_css(".step--active.step_3")
        end
      end

      it "show form and submit button" do
        expect(page).to have_field("Title", with: fiction_title)
        expect(page).to have_field("Body", with: fiction_body)
        expect(page).to have_button("Send")
      end

      context "when the back button is clicked" do
        before do
          create(:fiction, title: fiction_title, component: component)
          click_link "Back"
        end

        it "redirects to step_3: complete" do
          expect(page).to have_content("SIMILAR FICTIONS (1)")
        end
      end
    end

    context "when in step_4: Publish" do
      let!(:fiction_draft) { create(:fiction, :draft, users: [user], component: component, title: fiction_title, body: fiction_body) }

      before do
        visit component_path.preview_fiction_path(fiction_draft)
      end

      it "show current step_4 highlighted" do
        within ".wizard__steps" do
          expect(page).to have_css(".step--active", count: 1)
          expect(page).to have_css(".step--past", count: 3)
          expect(page).to have_css(".step--active.step_4")
        end
      end

      it "shows a preview" do
        expect(page).to have_content(fiction_title)
        expect(page).to have_content(user.name)
        expect(page).to have_content(fiction_body)
      end

      it "shows a publish button" do
        expect(page).to have_selector("button", text: "Publish")
      end

      it "shows a modify fiction link" do
        expect(page).to have_selector("a", text: "Modify the fiction")
      end

      context "when the back button is clicked" do
        before do
          click_link "Back"
        end

        it "redirects to edit the fiction draft" do
          expect(page).to have_content("EDIT FICTION DRAFT")
        end
      end
    end

    context "when editing a fiction draft" do
      context "when in step_4: edit fiction draft" do
        let!(:fiction_draft) { create(:fiction, :draft, users: [user], component: component, title: fiction_title, body: fiction_body) }
        let!(:edit_draft_fiction_path) do
          Decidim::EngineRouter.main_proxy(component).fiction_path(fiction_draft) + "/edit_draft"
        end

        before do
          visit edit_draft_fiction_path
        end

        it "show current step_4 highlighted" do
          within ".wizard__steps" do
            expect(page).to have_css(".step--active", count: 1)
            expect(page).to have_css(".step--past", count: 2)
            expect(page).to have_css(".step--active.step_3")
          end
        end

        it "can discard the draft" do
          within ".card__content" do
            expect(page).to have_content("Discard this draft")
            click_link "Discard this draft"
          end

          accept_confirm

          within_flash_messages do
            expect(page).to have_content "successfully"
          end
          expect(page).to have_css(".step--active.step_1")
        end

        it "renders a Preview button" do
          within ".card__content" do
            expect(page).to have_content("Preview")
          end
        end
      end
    end
  end
end
