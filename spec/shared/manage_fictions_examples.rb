# frozen_string_literal: true

shared_examples "manage fictions" do
  let(:address) { "Carrer Pare Llaurador 113, baixos, 08224 Terrassa" }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: participatory_process_scope) }
  let(:participatory_process_scope) { nil }

  before do
    stub_geocoding(address, [latitude, longitude])
  end

  context "when previewing fictions" do
    it "allows the user to preview the fiction" do
      within find("tr", text: fiction.title) do
        klass = "action-icon--preview"
        href = resource_locator(fiction).path
        target = "blank"

        expect(page).to have_selector(
          :xpath,
          "//a[contains(@class,'#{klass}')][@href='#{href}'][@target='#{target}']"
        )
      end
    end
  end

  describe "creation" do
    context "when official_fictions setting is enabled" do
      before do
        current_component.update!(settings: { official_fictions_enabled: true })
      end

      context "when creation is enabled" do
        before do
          current_component.update!(
            step_settings: {
              current_component.participatory_space.active_step.id => {
                creation_enabled: true
              }
            }
          )

          visit_component_admin
        end

        describe "admin form" do
          before { click_on "New fiction" }

          it_behaves_like "having a rich text editor", "new_fiction", "full"
        end

        context "when process is not related to any scope" do
          it "can be related to a scope" do
            click_link "New fiction"

            within "form" do
              expect(page).to have_content(/Scope/i)
            end
          end

          it "creates a new fiction", :slow do
            click_link "New fiction"

            within ".new_fiction" do
              fill_in :fiction_title, with: "Make decidim great again"
              fill_in_editor :fiction_body, with: "Decidim is great but it can be better"
              select translated(category.name), from: :fiction_category_id
              scope_pick select_data_picker(:fiction_scope_id), scope
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            within "table" do
              fiction = Decidim::Fictions::Fiction.last

              expect(page).to have_content("Make decidim great again")
              expect(fiction.body).to eq("<p>Decidim is great but it can be better</p>")
              expect(fiction.category).to eq(category)
              expect(fiction.scope).to eq(scope)
            end
          end
        end

        context "when process is related to a scope" do
          let(:participatory_process_scope) { scope }

          it "cannot be related to a scope, because it has no children" do
            click_link "New fiction"

            within "form" do
              expect(page).to have_no_content(/Scope/i)
            end
          end

          it "creates a new fiction related to the process scope" do
            click_link "New fiction"

            within ".new_fiction" do
              fill_in :fiction_title, with: "Make decidim great again"
              fill_in_editor :fiction_body, with: "Decidim is great but it can be better"
              select category.name["en"], from: :fiction_category_id
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            within "table" do
              fiction = Decidim::Fictions::Fiction.last

              expect(page).to have_content("Make decidim great again")
              expect(fiction.body).to eq("<p>Decidim is great but it can be better</p>")
              expect(fiction.category).to eq(category)
              expect(fiction.scope).to eq(scope)
            end
          end

          context "when the process scope has a child scope" do
            let!(:child_scope) { create :scope, parent: scope }

            it "can be related to a scope" do
              click_link "New fiction"

              within "form" do
                expect(page).to have_content(/Scope/i)
              end
            end

            it "creates a new fiction related to a process scope child" do
              click_link "New fiction"

              within ".new_fiction" do
                fill_in :fiction_title, with: "Make decidim great again"
                fill_in_editor :fiction_body, with: "Decidim is great but it can be better"
                select category.name["en"], from: :fiction_category_id
                scope_repick select_data_picker(:fiction_scope_id), scope, child_scope
                find("*[type=submit]").click
              end

              expect(page).to have_admin_callout("successfully")

              within "table" do
                fiction = Decidim::Fictions::Fiction.last

                expect(page).to have_content("Make decidim great again")
                expect(fiction.body).to eq("<p>Decidim is great but it can be better</p>")
                expect(fiction.category).to eq(category)
                expect(fiction.scope).to eq(child_scope)
              end
            end
          end

          context "when geocoding is enabled" do
            before do
              current_component.update!(settings: { geocoding_enabled: true })
            end

            it "creates a new fiction related to the process scope" do
              click_link "New fiction"

              within ".new_fiction" do
                fill_in :fiction_title, with: "Make decidim great again"
                fill_in_editor :fiction_body, with: "Decidim is great but it can be better"
                fill_in :fiction_address, with: address
                select category.name["en"], from: :fiction_category_id
                find("*[type=submit]").click
              end

              expect(page).to have_admin_callout("successfully")

              within "table" do
                fiction = Decidim::Fictions::Fiction.last

                expect(page).to have_content("Make decidim great again")
                expect(fiction.body).to eq("<p>Decidim is great but it can be better</p>")
                expect(fiction.category).to eq(category)
                expect(fiction.scope).to eq(scope)
              end
            end
          end
        end

        context "when attachments are allowed", processing_uploads_for: Decidim::AttachmentUploader do
          before do
            current_component.update!(settings: { attachments_allowed: true })
          end

          it "creates a new fiction with attachments" do
            click_link "New fiction"

            within ".new_fiction" do
              fill_in :fiction_title, with: "Fiction with attachments"
              fill_in_editor :fiction_body, with: "This is my fiction and I want to upload attachments."
              fill_in :fiction_attachment_title, with: "My attachment"
              attach_file :fiction_attachment_file, Decidim::Dev.asset("city.jpeg")
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            visit resource_locator(Decidim::Fictions::Fiction.last).path
            expect(page).to have_selector("img[src*=\"city.jpeg\"]", count: 1)
          end
        end

        context "when fictions comes from a meeting" do
          let!(:meeting_component) { create(:meeting_component, participatory_space: participatory_process) }
          let!(:meetings) { create_list(:meeting, 3, component: meeting_component) }

          it "creates a new fiction with meeting as author" do
            click_link "New fiction"

            within ".new_fiction" do
              fill_in :fiction_title, with: "Fiction with meeting as author"
              fill_in_editor :fiction_body, with: "Fiction body of meeting as author"
              execute_script("$('#fiction_created_in_meeting').change()")
              find(:css, "#fiction_created_in_meeting").set(true)
              select translated(meetings.first.title), from: :fiction_meeting_id
              select category.name["en"], from: :fiction_category_id
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            within "table" do
              fiction = Decidim::Fictions::Fiction.last

              expect(page).to have_content("Fiction with meeting as author")
              expect(fiction.body).to eq("<p>Fiction body of meeting as author</p>")
              expect(fiction.category).to eq(category)
            end
          end
        end
      end

      context "when creation is not enabled" do
        before do
          current_component.update!(
            step_settings: {
              current_component.participatory_space.active_step.id => {
                creation_enabled: false
              }
            }
          )
        end

        it "cannot create a new fiction from the main site" do
          visit_component
          expect(page).to have_no_button("New Fiction")
        end

        it "cannot create a new fiction from the admin site" do
          visit_component_admin
          expect(page).to have_no_link(/New/)
        end
      end
    end

    context "when official_fictions setting is disabled" do
      before do
        current_component.update!(settings: { official_fictions_enabled: false })
      end

      it "cannot create a new fiction from the main site" do
        visit_component
        expect(page).to have_no_button("New Fiction")
      end

      it "cannot create a new fiction from the admin site" do
        visit_component_admin
        expect(page).to have_no_link(/New/)
      end
    end
  end

  context "when the fiction_answering component setting is enabled" do
    before do
      current_component.update!(settings: { fiction_answering_enabled: true })
    end

    context "when the fiction_answering step setting is enabled" do
      before do
        current_component.update!(
          step_settings: {
            current_component.participatory_space.active_step.id => {
              fiction_answering_enabled: true
            }
          }
        )
      end

      it "can reject a fiction" do
        go_to_admin_fiction_page_answer_section(fiction)

        within ".edit_fiction_answer" do
          fill_in_i18n_editor(
            :fiction_answer_answer,
            "#fiction_answer-answer-tabs",
            en: "The fiction doesn't make any sense",
            es: "La propuesta no tiene sentido",
            ca: "La proposta no te sentit"
          )
          choose "Rejected"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Fiction successfully answered")

        within find("tr", text: fiction.title) do
          expect(page).to have_content("Rejected")
        end
      end

      it "can accept a fiction" do
        go_to_admin_fiction_page_answer_section(fiction)

        within ".edit_fiction_answer" do
          choose "Accepted"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Fiction successfully answered")

        within find("tr", text: fiction.title) do
          expect(page).to have_content("Accepted")
        end
      end

      it "can mark a fiction as evaluating" do
        go_to_admin_fiction_page_answer_section(fiction)

        within ".edit_fiction_answer" do
          choose "Evaluating"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Fiction successfully answered")

        within find("tr", text: fiction.title) do
          expect(page).to have_content("Evaluating")
        end
      end

      it "can edit a fiction answer" do
        fiction.update!(
          state: "rejected",
          answer: {
            "en" => "I don't like it"
          },
          answered_at: Time.current
        )

        visit_component_admin

        within find("tr", text: fiction.title) do
          expect(page).to have_content("Rejected")
        end

        go_to_admin_fiction_page_answer_section(fiction)

        within ".edit_fiction_answer" do
          choose "Accepted"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Fiction successfully answered")

        within find("tr", text: fiction.title) do
          expect(page).to have_content("Accepted")
        end
      end
    end

    context "when the fiction_answering step setting is disabled" do
      before do
        current_component.update!(
          step_settings: {
            current_component.participatory_space.active_step.id => {
              fiction_answering_enabled: false
            }
          }
        )
      end

      it "cannot answer a fiction" do
        visit current_path

        within find("tr", text: fiction.title) do
          expect(page).to have_no_link("Answer")
        end
      end
    end

    context "when the fiction is an emendation" do
      let!(:amendable) { create(:fiction, component: current_component) }
      let!(:emendation) { create(:fiction, component: current_component) }
      let!(:amendment) { create :amendment, amendable: amendable, emendation: emendation, state: "evaluating" }

      it "cannot answer a fiction" do
        visit_component_admin
        within find("tr", text: I18n.t("decidim/amendment", scope: "activerecord.models", count: 1)) do
          expect(page).to have_no_link("Answer")
        end
      end
    end
  end

  context "when the fiction_answering component setting is disabled" do
    before do
      current_component.update!(settings: { fiction_answering_enabled: false })
    end

    it "cannot answer a fiction" do
      go_to_admin_fiction_page(fiction)

      expect(page).to have_no_selector(".edit_fiction_answer")
    end
  end

  context "when the votes_enabled component setting is disabled" do
    before do
      current_component.update!(
        step_settings: {
          component.participatory_space.active_step.id => {
            votes_enabled: false
          }
        }
      )
    end

    it "doesn't show the votes column" do
      visit current_path

      within "thead" do
        expect(page).not_to have_content("VOTES")
      end
    end
  end

  context "when the votes_enabled component setting is enabled" do
    before do
      current_component.update!(
        step_settings: {
          component.participatory_space.active_step.id => {
            votes_enabled: true
          }
        }
      )
    end

    it "shows the votes column" do
      visit current_path

      within "thead" do
        expect(page).to have_content("Votes")
      end
    end
  end

  def go_to_admin_fiction_page(fiction)
    within find("tr", text: fiction.title) do
      find("a", class: "action-icon--show-fiction").click
    end
  end

  def go_to_admin_fiction_page_answer_section(fiction)
    go_to_admin_fiction_page(fiction)

    expect(page).to have_selector(".edit_fiction_answer")
  end
end
