# frozen_string_literal: true

require "spec_helper"

describe "Support Fiction", type: :system, slow: true do
  include_context "with a component"
  let(:manifest_name) { "fictions" }

  let!(:fictions) { create_list(:fiction, 3, component: component) }
  let!(:fiction) { Decidim::Fictions::Fiction.find_by(component: component) }
  let!(:user) { create :user, :confirmed, organization: organization }

  def expect_page_not_to_include_votes
    expect(page).to have_no_button("Support")
    expect(page).to have_no_css(".card__support__data span", text: "0 Supports")
  end

  context "when votes are not enabled" do
    context "when the user is not logged in" do
      it "doesn't show the vote fiction button and counts" do
        visit_component
        expect_page_not_to_include_votes

        click_link fiction.title
        expect_page_not_to_include_votes
      end
    end

    context "when the user is logged in" do
      before do
        login_as user, scope: :user
      end

      it "doesn't show the vote fiction button and counts" do
        visit_component
        expect_page_not_to_include_votes

        click_link fiction.title
        expect_page_not_to_include_votes
      end
    end
  end

  context "when votes are blocked" do
    let!(:component) do
      create(:fiction_component,
             :with_votes_blocked,
             manifest: manifest,
             participatory_space: participatory_process)
    end

    it "shows the vote count and the vote button is disabled" do
      visit_component
      expect_page_not_to_include_votes
    end
  end

  context "when votes are enabled" do
    let!(:component) do
      create(:fiction_component,
             :with_votes_enabled,
             manifest: manifest,
             participatory_space: participatory_process)
    end

    context "when the user is not logged in" do
      it "is given the option to sign in" do
        visit_component

        within ".card__support", match: :first do
          click_button "Support"
        end

        expect(page).to have_css("#loginModal", visible: :visible)
      end
    end

    context "when the user is logged in" do
      before do
        login_as user, scope: :user
      end

      context "when the fiction is not voted yet" do
        before do
          visit_component
        end

        it "is able to vote the fiction" do
          within "#fiction-#{fiction.id}-vote-button" do
            click_button "Support"
            expect(page).to have_button("Already supported")
          end

          within "#fiction-#{fiction.id}-votes-count" do
            expect(page).to have_content("1 Support")
          end
        end
      end

      context "when the fiction is already voted" do
        before do
          create(:fiction_vote, fiction: fiction, author: user)
          visit_component
        end

        it "is not able to vote it again" do
          within "#fiction-#{fiction.id}-vote-button" do
            expect(page).to have_button("Already supported")
            expect(page).to have_no_button("Support")
          end

          within "#fiction-#{fiction.id}-votes-count" do
            expect(page).to have_content("1 Support")
          end
        end

        it "is able to undo the vote" do
          within "#fiction-#{fiction.id}-vote-button" do
            click_button "Already supported"
            expect(page).to have_button("Support")
          end

          within "#fiction-#{fiction.id}-votes-count" do
            expect(page).to have_content("0 Supports")
          end
        end
      end

      context "when the component has a vote limit" do
        let(:vote_limit) { 10 }

        let!(:component) do
          create(:fiction_component,
                 :with_votes_enabled,
                 :with_vote_limit,
                 vote_limit: vote_limit,
                 manifest: manifest,
                 participatory_space: participatory_process)
        end

        describe "vote counter" do
          context "when votes are blocked" do
            let!(:component) do
              create(:fiction_component,
                     :with_votes_blocked,
                     :with_vote_limit,
                     vote_limit: vote_limit,
                     manifest: manifest,
                     participatory_space: participatory_process)
            end

            it "doesn't show the remaining votes counter" do
              visit_component

              expect(page).to have_css(".voting-rules")
              expect(page).to have_no_css(".remaining-votes-counter")
            end
          end

          context "when votes are enabled" do
            let!(:component) do
              create(:fiction_component,
                     :with_votes_enabled,
                     :with_vote_limit,
                     vote_limit: vote_limit,
                     manifest: manifest,
                     participatory_space: participatory_process)
            end

            it "shows the remaining votes counter" do
              visit_component

              expect(page).to have_css(".voting-rules")
              expect(page).to have_css(".remaining-votes-counter")
            end
          end
        end

        context "when the fiction is not voted yet" do
          before do
            visit_component
          end

          it "updates the remaining votes counter" do
            within "#fiction-#{fiction.id}-vote-button" do
              click_button "Support"
              expect(page).to have_button("Already supported")
            end

            expect(page).to have_content("REMAINING\n9\nSupports")
          end
        end

        context "when the fiction is not voted yet but the user isn't authorized" do
          before do
            permissions = {
              vote: {
                authorization_handlers: {
                  "dummy_authorization_handler" => { "options" => {} }
                }
              }
            }

            component.update!(permissions: permissions)
            visit_component
          end

          it "shows a modal dialog" do
            within "#fiction-#{fiction.id}-vote-button" do
              click_button "Support"
            end

            expect(page).to have_content("Authorization required")
          end
        end

        context "when the fiction is already voted" do
          before do
            create(:fiction_vote, fiction: fiction, author: user)
            visit_component
          end

          it "is not able to vote it again" do
            within "#fiction-#{fiction.id}-vote-button" do
              expect(page).to have_button("Already supported")
              expect(page).to have_no_button("Support")
            end
          end

          it "is able to undo the vote" do
            within "#fiction-#{fiction.id}-vote-button" do
              click_button "Already supported"
              expect(page).to have_button("Support")
            end

            within "#fiction-#{fiction.id}-votes-count" do
              expect(page).to have_content("0 Supports")
            end

            expect(page).to have_content("REMAINING\n10\nSupports")
          end
        end

        context "when the user has reached the votes limit" do
          let(:vote_limit) { 1 }

          before do
            create(:fiction_vote, fiction: fiction, author: user)
            visit_component
          end

          it "is not able to vote other fictions" do
            expect(page).to have_css(".button[disabled]", count: 2)
          end

          context "when votes are blocked" do
            let!(:component) do
              create(:fiction_component,
                     :with_votes_blocked,
                     manifest: manifest,
                     participatory_space: participatory_process)
            end

            it "shows the vote count but not the vote button" do
              within "#fiction_#{fiction.id} .card__support" do
                expect(page).to have_content("1 Support")
              end

              expect(page).to have_content("Supports disabled")
            end
          end
        end
      end
    end

    context "when the fiction is rejected", :slow do
      let!(:rejected_fiction) { create(:fiction, :rejected, component: component) }

      before do
        component.update!(settings: { fiction_answering_enabled: true })
      end

      it "cannot be voted" do
        visit_component

        within ".filters .state_check_boxes_tree_filter" do
          check "All"
          uncheck "All"
          check "Rejected"
        end

        page.find_link rejected_fiction.title
        expect(page).to have_no_selector("#fiction-#{rejected_fiction.id}-vote-button")

        click_link rejected_fiction.title
        expect(page).to have_no_selector("#fiction-#{rejected_fiction.id}-vote-button")
      end
    end

    context "when fictions have a voting limit" do
      let!(:component) do
        create(:fiction_component,
               :with_votes_enabled,
               :with_threshold_per_fiction,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      before do
        login_as user, scope: :user
      end

      it "doesn't allow users to vote to a fiction that's reached the limit" do
        create(:fiction_vote, fiction: fiction)
        visit_component

        fiction_element = page.find(".card--fiction", text: fiction.title)

        within fiction_element do
          within ".card__support", match: :first do
            expect(page).to have_content("Support limit reached")
          end
        end
      end

      it "allows users to vote on fictions under the limit" do
        visit_component

        fiction_element = page.find(".card--fiction", text: fiction.title)

        within fiction_element do
          within ".card__support", match: :first do
            click_button "Support"
            expect(page).to have_content("Already supported")
          end
        end
      end
    end

    context "when fictions have vote limit but can accumulate more votes" do
      let!(:component) do
        create(:fiction_component,
               :with_votes_enabled,
               :with_threshold_per_fiction,
               :with_can_accumulate_supports_beyond_threshold,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      before do
        login_as user, scope: :user
      end

      it "allows users to vote on fictions over the limit" do
        create(:fiction_vote, fiction: fiction)
        visit_component

        fiction_element = page.find(".card--fiction", text: fiction.title)

        within fiction_element do
          within ".card__support", match: :first do
            expect(page).to have_content("1 Support")
          end
        end
      end
    end

    context "when fictions have a minimum amount of votes" do
      let!(:component) do
        create(:fiction_component,
               :with_votes_enabled,
               :with_minimum_votes_per_user,
               minimum_votes_per_user: 3,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      before do
        login_as user, scope: :user
      end

      it "doesn't count votes unless the minimum is achieved" do
        visit_component

        fiction_elements = fictions.map do |fiction|
          page.find(".card--fiction", text: fiction.title)
        end

        within fiction_elements[0] do
          click_button "Support"
          expect(page).to have_content("Already supported")
          expect(page).to have_content("0 Supports")
        end

        within fiction_elements[1] do
          click_button "Support"
          expect(page).to have_content("Already supported")
          expect(page).to have_content("0 Supports")
        end

        within fiction_elements[2] do
          click_button "Support"
          expect(page).to have_content("Already supported")
          expect(page).to have_content("1 Support")
        end

        within fiction_elements[0] do
          expect(page).to have_content("1 Support")
        end

        within fiction_elements[1] do
          expect(page).to have_content("1 Support")
        end
      end
    end

    describe "gamification" do
      before do
        login_as user, scope: :user
      end

      it "gives a point after voting" do
        visit_component

        fiction_element = page.find(".card--fiction", text: fiction.title)

        expect do
          within fiction_element do
            within ".card__support", match: :first do
              click_button "Support"
              expect(page).to have_content("1 Support")
            end
          end
        end.to change { Decidim::Gamification.status_for(user, :fiction_votes).score }.by(1)
      end
    end
  end
end
