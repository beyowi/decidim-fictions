# frozen_string_literal: true

require "spec_helper"

describe "Filter Fictions", :slow, type: :system do
  include_context "with a component"
  let(:manifest_name) { "fictions" }

  let!(:category) { create :category, participatory_space: participatory_process }
  let!(:scope) { create :scope, organization: organization }
  let!(:user) { create :user, :confirmed, organization: organization }
  let(:scoped_participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: scope) }

  context "when filtering fictions by ORIGIN" do
    context "when official_fictions setting is enabled" do
      before do
        component.update!(settings: { official_fictions_enabled: true })
      end

      it "can be filtered by origin" do
        visit_component

        within "form.new_filter" do
          expect(page).to have_content(/Origin/i)
        end
      end

      context "with 'official' origin" do
        it "lists the filtered fictions" do
          create_list(:fiction, 2, :official, component: component, scope: scope)
          create(:fiction, component: component, scope: scope)
          visit_component

          within ".filters .origin_check_boxes_tree_filter" do
            uncheck "All"
            check "Official"
          end

          expect(page).to have_css(".card--fiction", count: 2)
          expect(page).to have_content("2 FICTIONS")
        end
      end

      context "with 'citizens' origin" do
        it "lists the filtered fictions" do
          create_list(:fiction, 2, component: component, scope: scope)
          create(:fiction, :official, component: component, scope: scope)
          visit_component

          within ".filters .origin_check_boxes_tree_filter" do
            uncheck "All"
            check "Citizens"
          end

          expect(page).to have_css(".card--fiction", count: 2)
          expect(page).to have_content("2 FICTIONS")
        end
      end
    end

    context "when official_fictions setting is not enabled" do
      before do
        component.update!(settings: { official_fictions_enabled: false })
      end

      it "cannot be filtered by origin" do
        visit_component

        within "form.new_filter" do
          expect(page).to have_no_content(/Official/i)
        end
      end
    end
  end

  context "when filtering fictions by SCOPE" do
    let(:scopes_picker) { select_data_picker(:filter_scope_id, multiple: true, global_value: "global") }
    let!(:scope2) { create :scope, organization: participatory_process.organization }

    before do
      create_list(:fiction, 2, component: component, scope: scope)
      create(:fiction, component: component, scope: scope2)
      create(:fiction, component: component, scope: nil)
      visit_component
    end

    it "can be filtered by scope" do
      within "form.new_filter" do
        expect(page).to have_content(/Scope/i)
      end
    end

    context "when selecting the global scope" do
      it "lists the filtered fictions", :slow do
        within ".filters .scope_id_check_boxes_tree_filter" do
          uncheck "All"
          check "Global"
        end

        expect(page).to have_css(".card--fiction", count: 1)
        expect(page).to have_content("1 FICTION")
      end
    end

    context "when selecting one scope" do
      it "lists the filtered fictions", :slow do
        within ".filters .scope_id_check_boxes_tree_filter" do
          uncheck "All"
          check scope.name[I18n.locale.to_s]
        end

        expect(page).to have_css(".card--fiction", count: 2)
        expect(page).to have_content("2 FICTIONS")
      end
    end

    context "when selecting the global scope and another scope" do
      it "lists the filtered fictions", :slow do
        within ".filters .scope_id_check_boxes_tree_filter" do
          uncheck "All"
          check "Global"
          check scope.name[I18n.locale.to_s]
        end

        expect(page).to have_css(".card--fiction", count: 3)
        expect(page).to have_content("3 FICTIONS")
      end
    end

    context "when unselecting the selected scope" do
      it "lists the filtered fictions" do
        within ".filters .scope_id_check_boxes_tree_filter" do
          uncheck "All"
          check scope.name[I18n.locale.to_s]
          check "Global"
          uncheck scope.name[I18n.locale.to_s]
        end

        expect(page).to have_css(".card--fiction", count: 1)
        expect(page).to have_content("1 FICTION")
      end
    end

    context "when process is related to a scope" do
      let(:participatory_process) { scoped_participatory_process }

      it "cannot be filtered by scope" do
        visit_component

        within "form.new_filter" do
          expect(page).to have_no_content(/Scope/i)
        end
      end

      context "with subscopes" do
        let!(:subscopes) { create_list :subscope, 5, parent: scope }

        it "can be filtered by scope" do
          visit_component

          within "form.new_filter" do
            expect(page).to have_content(/Scope/i)
          end
        end
      end
    end
  end

  context "when filtering fictions by STATE" do
    context "when fiction_answering component setting is enabled" do
      before do
        component.update!(settings: { fiction_answering_enabled: true })
      end

      context "when fiction_answering step setting is enabled" do
        before do
          component.update!(
            step_settings: {
              component.participatory_space.active_step.id => {
                fiction_answering_enabled: true
              }
            }
          )
        end

        it "can be filtered by state" do
          visit_component

          within "form.new_filter" do
            expect(page).to have_content(/Status/i)
          end
        end

        it "lists accepted fictions" do
          create(:fiction, :accepted, component: component, scope: scope)
          visit_component

          within ".filters .state_check_boxes_tree_filter" do
            check "All"
            uncheck "All"
            check "Accepted"
          end

          expect(page).to have_css(".card--fiction", count: 1)
          expect(page).to have_content("1 FICTION")

          within ".card--fiction" do
            expect(page).to have_content("ACCEPTED")
          end
        end

        it "lists the filtered fictions" do
          create(:fiction, :rejected, component: component, scope: scope)
          visit_component

          within ".filters .state_check_boxes_tree_filter" do
            check "All"
            uncheck "All"
            check "Rejected"
          end

          expect(page).to have_css(".card--fiction", count: 1)
          expect(page).to have_content("1 FICTION")

          within ".card--fiction" do
            expect(page).to have_content("REJECTED")
          end
        end

        context "when there are fictions with answers not published" do
          let!(:fiction) { create(:fiction, :accepted_not_published, component: component, scope: scope) }

          before do
            create(:fiction, :accepted, component: component, scope: scope)

            visit_component
          end

          it "shows only accepted fictions with published answers" do
            within ".filters .state_check_boxes_tree_filter" do
              check "All"
              uncheck "All"
              check "Accepted"
            end

            expect(page).to have_css(".card--fiction", count: 1)
            expect(page).to have_content("1 FICTION")

            within ".card--fiction" do
              expect(page).to have_content("ACCEPTED")
            end
          end

          it "shows accepted fictions with not published answers as not answered" do
            within ".filters .state_check_boxes_tree_filter" do
              check "All"
              uncheck "All"
              check "Not answered"
            end

            expect(page).to have_css(".card--fiction", count: 1)
            expect(page).to have_content("1 FICTION")

            within ".card--fiction" do
              expect(page).to have_content(fiction.title)
              expect(page).not_to have_content("ACCEPTED")
            end
          end
        end
      end

      context "when fiction_answering step setting is disabled" do
        before do
          component.update!(
            step_settings: {
              component.participatory_space.active_step.id => {
                fiction_answering_enabled: false
              }
            }
          )
        end

        it "cannot be filtered by state" do
          visit_component

          within "form.new_filter" do
            expect(page).to have_no_content(/Status/i)
          end
        end
      end
    end

    context "when fiction_answering component setting is not enabled" do
      before do
        component.update!(settings: { fiction_answering_enabled: false })
      end

      it "cannot be filtered by state" do
        visit_component

        within "form.new_filter" do
          expect(page).to have_no_content(/Status/i)
        end
      end
    end
  end

  context "when filtering fictions by CATEGORY", :slow do
    context "when the user is logged in" do
      let!(:category2) { create :category, participatory_space: participatory_process }
      let!(:category3) { create :category, participatory_space: participatory_process }
      let!(:fiction1) { create(:fiction, component: component, category: category) }
      let!(:fiction2) { create(:fiction, component: component, category: category2) }
      let!(:fiction3) { create(:fiction, component: component, category: category3) }

      before do
        login_as user, scope: :user
      end

      it "can be filtered by a category" do
        visit_component

        within ".filters .category_id_check_boxes_tree_filter" do
          uncheck "All"
          check category.name[I18n.locale.to_s]
        end

        expect(page).to have_css(".card--fiction", count: 1)
      end

      it "can be filtered by two categories" do
        visit_component

        within ".filters .category_id_check_boxes_tree_filter" do
          uncheck "All"
          check category.name[I18n.locale.to_s]
          check category2.name[I18n.locale.to_s]
        end

        expect(page).to have_css(".card--fiction", count: 2)
      end
    end
  end

  context "when filtering fictions by ACTIVITY" do
    let(:active_step_id) { component.participatory_space.active_step.id }
    let!(:voted_fiction) { create(:fiction, component: component) }
    let!(:vote) { create(:fiction_vote, fiction: voted_fiction, author: user) }
    let!(:fiction_list) { create_list(:fiction, 3, component: component) }
    let!(:created_fiction) { create(:fiction, component: component, users: [user]) }

    context "when the user is logged in" do
      before do
        login_as user, scope: :user
        visit_component
      end

      it "can be filtered by activity" do
        within "form.new_filter" do
          expect(page).to have_content(/Activity/i)
        end
      end

      it "can be filtered by my fictions" do
        within "form.new_filter" do
          expect(page).to have_content(/My fictions/i)
        end
      end

      it "lists the filtered fictions created by the user" do
        within "form.new_filter" do
          find("input[value='my_fictions']").click
        end
        expect(page).to have_css(".card--fiction", count: 1)
      end

      context "when votes are enabled" do
        before do
          component.update!(step_settings: { active_step_id => { votes_enabled: true } })
          visit_component
        end

        it "can be filtered by supported" do
          within "form.new_filter" do
            expect(page).to have_content(/Supported/i)
          end
        end

        it "lists the filtered fictions voted by the user" do
          within "form.new_filter" do
            find("input[value='voted']").click
          end

          expect(page).to have_css(".card--fiction", text: voted_fiction.title)
        end
      end

      context "when votes are not enabled" do
        before do
          component.update!(step_settings: { active_step_id => { votes_enabled: false } })
          visit_component
        end

        it "cannot be filtered by supported" do
          within "form.new_filter" do
            expect(page).not_to have_content(/Supported/i)
          end
        end
      end
    end

    context "when the user is NOT logged in" do
      it "cannot be filtered by activity" do
        visit_component
        within "form.new_filter" do
          expect(page).not_to have_content(/Activity/i)
        end
      end
    end
  end

  context "when filtering fictions by TYPE" do
    context "when there are amendments to fictions" do
      let!(:fiction) { create(:fiction, component: component, scope: scope) }
      let!(:emendation) { create(:fiction, component: component, scope: scope) }
      let!(:amendment) { create(:amendment, amendable: fiction, emendation: emendation) }

      before do
        visit_component
      end

      context "with 'all' type" do
        it "lists the filtered fictions" do
          find('input[name="filter[type]"][value="all"]').click

          expect(page).to have_css(".card.card--fiction", count: 2)
          expect(page).to have_content("2 FICTIONS")
          expect(page).to have_content("Amendment", count: 2)
        end
      end

      context "with 'fictions' type" do
        it "lists the filtered fictions" do
          within ".filters" do
            choose "Fictions"
          end

          expect(page).to have_css(".card.card--fiction", count: 1)
          expect(page).to have_content("1 FICTION")
          expect(page).to have_content("Amendment", count: 1)
        end
      end

      context "with 'amendments' type" do
        it "lists the filtered fictions" do
          within ".filters" do
            choose "Amendments"
          end

          expect(page).to have_css(".card.card--fiction", count: 1)
          expect(page).to have_content("1 FICTION")
          expect(page).to have_content("Amendment", count: 2)
        end
      end

      context "when amendments_enabled component setting is enabled" do
        before do
          component.update!(settings: { amendments_enabled: true })
        end

        context "and amendments_visbility component step_setting is set to 'participants'" do
          before do
            component.update!(
              step_settings: {
                component.participatory_space.active_step.id => {
                  amendments_visibility: "participants"
                }
              }
            )
          end

          context "when the user is logged in" do
            context "and has amended a fiction" do
              let!(:new_emendation) { create(:fiction, component: component, scope: scope) }
              let!(:new_amendment) { create(:amendment, amendable: fiction, emendation: new_emendation, amender: new_emendation.creator_author) }
              let(:user) { new_amendment.amender }

              before do
                login_as user, scope: :user
                visit_component
              end

              it "can be filtered by type" do
                within "form.new_filter" do
                  expect(page).to have_content(/Type/i)
                end
              end

              it "lists only their amendments" do
                within ".filters" do
                  choose "Amendments"
                end
                expect(page).to have_css(".card.card--fiction", count: 1)
                expect(page).to have_content("1 FICTION")
                expect(page).to have_content("Amendment", count: 2)
                expect(page).to have_content(new_emendation.title)
                expect(page).to have_no_content(emendation.title)
              end
            end

            context "and has NOT amended a fiction" do
              before do
                login_as user, scope: :user
                visit_component
              end

              it "cannot be filtered by type" do
                within "form.new_filter" do
                  expect(page).to have_no_content(/Type/i)
                end
              end
            end
          end

          context "when the user is NOT logged in" do
            before do
              visit_component
            end

            it "cannot be filtered by type" do
              within "form.new_filter" do
                expect(page).to have_no_content(/Type/i)
              end
            end
          end
        end
      end

      context "when amendments_enabled component setting is NOT enabled" do
        before do
          component.update!(settings: { amendments_enabled: false })
        end

        context "and amendments_visbility component step_setting is set to 'participants'" do
          before do
            component.update!(
              step_settings: {
                component.participatory_space.active_step.id => {
                  amendments_visibility: "participants"
                }
              }
            )
          end

          context "when the user is logged in" do
            context "and has amended a fiction" do
              let!(:new_emendation) { create(:fiction, component: component, scope: scope) }
              let!(:new_amendment) { create(:amendment, amendable: fiction, emendation: new_emendation, amender: new_emendation.creator_author) }
              let(:user) { new_amendment.amender }

              before do
                login_as user, scope: :user
                visit_component
              end

              it "can be filtered by type" do
                within "form.new_filter" do
                  expect(page).to have_content(/Type/i)
                end
              end

              it "lists all the amendments" do
                within ".filters" do
                  choose "Amendments"
                end
                expect(page).to have_css(".card.card--fiction", count: 2)
                expect(page).to have_content("2 FICTION")
                expect(page).to have_content("Amendment", count: 3)
                expect(page).to have_content(new_emendation.title)
                expect(page).to have_content(emendation.title)
              end
            end

            context "and has NOT amended a fiction" do
              before do
                login_as user, scope: :user
                visit_component
              end

              it "can be filtered by type" do
                within "form.new_filter" do
                  expect(page).to have_content(/Type/i)
                end
              end
            end
          end

          context "when the user is NOT logged in" do
            before do
              visit_component
            end

            it "can be filtered by type" do
              within "form.new_filter" do
                expect(page).to have_content(/Type/i)
              end
            end
          end
        end
      end
    end
  end

  context "when using the browser history", :slow do
    before do
      create_list(:fiction, 2, component: component)
      create_list(:fiction, 2, :official, component: component)
      create_list(:fiction, 2, :official, :accepted, component: component)
      create_list(:fiction, 2, :official, :rejected, component: component)

      visit_component
    end

    it "recover filters from initial pages" do
      within ".filters .state_check_boxes_tree_filter" do
        check "Rejected"
      end

      expect(page).to have_css(".card.card--fiction", count: 8)

      page.go_back

      expect(page).to have_css(".card.card--fiction", count: 6)
    end

    it "recover filters from previous pages" do
      within ".filters .state_check_boxes_tree_filter" do
        check "All"
        uncheck "All"
      end
      within ".filters .origin_check_boxes_tree_filter" do
        uncheck "All"
      end

      within ".filters .origin_check_boxes_tree_filter" do
        check "Official"
      end

      within ".filters .state_check_boxes_tree_filter" do
        check "Accepted"
      end

      expect(page).to have_css(".card.card--fiction", count: 2)

      page.go_back

      expect(page).to have_css(".card.card--fiction", count: 6)

      page.go_back

      expect(page).to have_css(".card.card--fiction", count: 8)

      page.go_forward

      expect(page).to have_css(".card.card--fiction", count: 6)
    end
  end
end
