# frozen_string_literal: true

require "spec_helper"

describe "Participatory texts", type: :system do
  include Decidim::SanitizeHelper
  include ActionView::Helpers::TextHelper

  include_context "with a component"
  let(:manifest_name) { "fictions" }

  def update_step_settings(new_step_settings)
    active_step_id = participatory_process.active_step.id.to_s
    step_settings = component.step_settings[active_step_id].to_h.merge(new_step_settings)
    component.update!(
      settings: component.settings.to_h.merge(amendments_enabled: true),
      step_settings: { active_step_id => step_settings }
    )
  end

  def should_have_fiction(selector, fiction)
    expect(page).to have_tag(selector, text: fiction.title)
    prop_block = page.find(selector)
    prop_block.hover
    clean_fiction_body = strip_tags(fiction.body)

    expect(prop_block).to have_button("Follow")
    expect(prop_block).to have_link("Comment") if component.settings.comments_enabled
    expect(prop_block).to have_link(fiction.comments.count.to_s) if component.settings.comments_enabled
    expect(prop_block).to have_content(clean_fiction_body) if fiction.participatory_text_level == "article"
    expect(prop_block).not_to have_content(clean_fiction_body) if fiction.participatory_text_level != "article"
  end

  shared_examples_for "lists all the fictions ordered" do
    it "by position" do
      visit_component
      expect(page).to have_css(".hover-section", count: fictions.count)
      fictions.each_with_index do |fiction, index|
        should_have_fiction("#fictions div.hover-section:nth-child(#{index + 1})", fiction)
      end
    end

    context " when participatory text level is not article" do
      it "not renders the participatory text body" do
        fiction_section = fictions.first
        fiction_section.participatory_text_level = "section"
        fiction_section.save!
        visit_component
        should_have_fiction("#fictions div.hover-section:first-child", fiction_section)
      end
    end

    context "when participatory text level is article" do
      it "renders the fiction body" do
        fiction_article = fictions.last
        fiction_article.participatory_text_level = "article"
        fiction_article.save!
        visit_component
        should_have_fiction("#fictions div.hover-section:last-child", fiction_article)
      end
    end
  end

  shared_examples "showing the Amend buttton and amendments counter when hovered" do
    let(:amend_button_disabled?) { page.find("a", text: "AMEND")[:disabled].present? }

    it "shows the Amend buttton and amendments counter inside the fiction div" do
      visit_component
      find("#fictions div.hover-section", text: fictions.first.title).hover
      within all("#fictions div.hover-section").first, visible: true do
        within ".amend-buttons" do
          expect(page).to have_link("Amend")
          expect(amend_button_disabled?).to eq(disabled_value)
          expect(page).to have_link(amendments_count)
        end
      end
    end
  end

  shared_examples "hiding the Amend buttton and amendments counter when hovered" do
    it "hides the Amend buttton and amendments counter inside the fiction div" do
      visit_component
      find("#fictions div.hover-section", text: fictions.first.title).hover
      within all("#fictions div.hover-section").first, visible: true do
        expect(page).not_to have_css(".amend-buttons")
      end
    end
  end

  context "when listing fictions in a participatory process as participatory texts" do
    context "when admin has not yet published a participatory text" do
      let!(:component) do
        create(:fiction_component,
               :with_participatory_texts_enabled,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      before do
        visit_component
      end

      it "renders an alternative title" do
        expect(page).to have_content("There are no participatory texts at the moment")
      end
    end

    context "when admin has published a participatory text" do
      let!(:participatory_text) { create :participatory_text, component: component }
      let!(:fictions) { create_list(:fiction, 3, :published, component: component) }
      let!(:component) do
        create(:fiction_component,
               :with_participatory_texts_enabled,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      it_behaves_like "lists all the fictions ordered"

      it "renders the participatory text title" do
        visit_component

        expect(page).to have_content(participatory_text.title)
      end

      context "without existing amendments" do
        context "when amendment CREATION is enabled" do
          before { update_step_settings(amendment_creation_enabled: true) }

          it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
            let(:amendments_count) { 0 }
            let(:disabled_value) { false }
          end
        end

        context "when amendment CREATION is disabled" do
          before { update_step_settings(amendment_creation_enabled: false) }

          it_behaves_like "hiding the Amend buttton and amendments counter when hovered"
        end
      end

      context "with existing amendments" do
        let!(:emendation_1) { create(:fiction, :published, component: component) }
        let!(:amendment_1) { create :amendment, amendable: fictions.first, emendation: emendation_1 }
        let!(:emendation_2) { create(:fiction, component: component) }
        let!(:amendment_2) { create(:amendment, amendable: fictions.first, emendation: emendation_2) }
        let(:user) { amendment_1.amender }

        context "when amendment CREATION is enabled" do
          before { update_step_settings(amendment_creation_enabled: true) }

          context "and amendments VISIBILITY is set to 'all'" do
            before { update_step_settings(amendments_visibility: "all") }

            context "when the user is logged in" do
              before { login_as user, scope: :user }

              it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
                let(:amendments_count) { 2 }
                let(:disabled_value) { false }
              end
            end

            context "when the user is NOT logged in" do
              it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
                let(:amendments_count) { 2 }
                let(:disabled_value) { false }
              end
            end
          end

          context "and amendments VISIBILITY is set to 'participants'" do
            before { update_step_settings(amendments_visibility: "participants") }

            context "when the user is logged in" do
              before { login_as user, scope: :user }

              it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
                let(:amendments_count) { 1 }
                let(:disabled_value) { false }
              end
            end

            context "when the user is NOT logged in" do
              it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
                let(:amendments_count) { 0 }
                let(:disabled_value) { false }
              end
            end
          end
        end

        context "when amendment CREATION is disabled" do
          before { update_step_settings(amendment_creation_enabled: false) }

          context "and amendments VISIBILITY is set to 'all'" do
            before { update_step_settings(amendments_visibility: "all") }

            context "when the user is logged in" do
              let(:user) { amendment_1.amender }

              before { login_as user, scope: :user }

              it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
                let(:amendments_count) { 2 }
                let(:disabled_value) { true }
              end
            end

            context "when the user is NOT logged in" do
              it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
                let(:amendments_count) { 2 }
                let(:disabled_value) { true }
              end
            end
          end

          context "and amendments VISIBILITY is set to 'participants'" do
            before { update_step_settings(amendments_visibility: "participants") }

            context "when the user is logged in" do
              let(:user) { amendment_1.amender }

              before { login_as user, scope: :user }

              it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
                let(:amendments_count) { 1 }
                let(:disabled_value) { true }
              end
            end

            context "when the user is NOT logged in" do
              it_behaves_like "hiding the Amend buttton and amendments counter when hovered"
            end
          end
        end
      end

      context "when comments are enabled" do
        let!(:component) do
          create(:fiction_component,
                 :with_participatory_texts_enabled,
                 :with_votes_enabled,
                 manifest: manifest,
                 participatory_space: participatory_process)
        end

        it_behaves_like "lists all the fictions ordered"
      end

      context "when comments are disabled" do
        let(:component) do
          create(:fiction_component,
                 :with_comments_disabled,
                 :with_participatory_texts_enabled,
                 manifest: manifest,
                 participatory_space: participatory_process)
        end

        it_behaves_like "lists all the fictions ordered"
      end
    end
  end
end
