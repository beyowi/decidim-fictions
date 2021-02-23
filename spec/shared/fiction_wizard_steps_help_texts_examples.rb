# frozen_string_literal: true

shared_examples "manage fiction wizard steps help texts" do
  before do
    current_component.update!(
      step_settings: {
        current_component.participatory_space.active_step.id => {
          creation_enabled: true
        }
      }
    )
  end

  let!(:fiction) { create(:fiction, component: current_component) }
  let!(:fiction_similar) { create(:fiction, component: current_component, title: "This fiction is to ensure a similar exists") }
  let!(:fiction_draft) { create(:fiction, :draft, component: current_component, title: "This fiction has a similar") }

  it "customize the help text for step 1 of the fiction wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_fiction_wizard_step_1_help_text,
      "#global-settings-fiction_wizard_step_1_help_text-tabs",
      en: "This is the first step of the Fiction creation wizard.",
      es: "Este es el primer paso del asistente de creación de propuestas.",
      ca: "Aquest és el primer pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    visit new_fiction_path(current_component)
    within ".fiction_wizard_help_text" do
      expect(page).to have_content("This is the first step of the Fiction creation wizard.")
    end
  end

  it "customize the help text for step 2 of the fiction wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_fiction_wizard_step_2_help_text,
      "#global-settings-fiction_wizard_step_2_help_text-tabs",
      en: "This is the second step of the Fiction creation wizard.",
      es: "Este es el segundo paso del asistente de creación de propuestas.",
      ca: "Aquest és el segon pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    create(:fiction, title: "More sidewalks and less roads", body: "Cities need more people, not more cars", component: component)
    create(:fiction, title: "More trees and parks", body: "Green is always better", component: component)
    visit_component
    click_link "New fiction"
    within ".new_fiction" do
      fill_in :fiction_title, with: "More sidewalks and less roads"
      fill_in :fiction_body, with: "Cities need more people, not more cars"

      find("*[type=submit]").click
    end

    within ".fiction_wizard_help_text" do
      expect(page).to have_content("This is the second step of the Fiction creation wizard.")
    end
  end

  it "customize the help text for step 3 of the fiction wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_fiction_wizard_step_3_help_text,
      "#global-settings-fiction_wizard_step_3_help_text-tabs",
      en: "This is the third step of the Fiction creation wizard.",
      es: "Este es el tercer paso del asistente de creación de propuestas.",
      ca: "Aquest és el tercer pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    visit_component
    click_link "New fiction"
    within ".new_fiction" do
      fill_in :fiction_title, with: "More sidewalks and less roads"
      fill_in :fiction_body, with: "Cities need more people, not more cars"

      find("*[type=submit]").click
    end

    within ".fiction_wizard_help_text" do
      expect(page).to have_content("This is the third step of the Fiction creation wizard.")
    end
  end

  it "customize the help text for step 4 of the fiction wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_fiction_wizard_step_4_help_text,
      "#global-settings-fiction_wizard_step_4_help_text-tabs",
      en: "This is the fourth step of the Fiction creation wizard.",
      es: "Este es el cuarto paso del asistente de creación de propuestas.",
      ca: "Aquest és el quart pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    visit preview_fiction_path(current_component, fiction_draft)
    within ".fiction_wizard_help_text" do
      expect(page).to have_content("This is the fourth step of the Fiction creation wizard.")
    end
  end

  private

  def new_fiction_path(current_component)
    Decidim::EngineRouter.main_proxy(current_component).new_fiction_path(current_component.id)
  end

  def complete_fiction_path(current_component, fiction)
    Decidim::EngineRouter.main_proxy(current_component).complete_fiction_path(fiction)
  end

  def preview_fiction_path(current_component, fiction)
    Decidim::EngineRouter.main_proxy(current_component).fiction_path(fiction) + "/preview"
  end
end
