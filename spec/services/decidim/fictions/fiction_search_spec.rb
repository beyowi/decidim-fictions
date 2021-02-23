# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    describe FictionSearch do
      let(:component) { create(:component, manifest_name: "fictions") }
      let(:scope1) { create :scope, organization: component.organization }
      let(:scope2) { create :scope, organization: component.organization }
      let(:subscope1) { create :scope, organization: component.organization, parent: scope1 }
      let(:participatory_process) { component.participatory_space }
      let(:user) { create(:user, organization: component.organization) }
      let!(:fiction) { create(:fiction, component: component, scope: scope1) }

      describe "results" do
        subject do
          described_class.new(
            component: component,
            activity: activity,
            search_text: search_text,
            state: states,
            origin: origins,
            related_to: related_to,
            scope_id: scope_ids,
            category_id: category_ids,
            current_user: user
          ).results
        end

        let(:activity) { [] }
        let(:search_text) { nil }
        let(:origins) { nil }
        let(:related_to) { nil }
        let(:states) { nil }
        let(:scope_ids) { nil }
        let(:category_ids) { nil }

        it "only includes fictions from the given component" do
          other_fiction = create(:fiction)

          expect(subject).to include(fiction)
          expect(subject).not_to include(other_fiction)
        end

        describe "search_text filter" do
          let(:search_text) { "dog" }

          it "returns the fictions containing the search in the title or the body" do
            create_list(:fiction, 3, component: component)
            create(:fiction, title: "A dog", component: component)
            create(:fiction, body: "There is a dog in the office", component: component)

            expect(subject.size).to eq(2)
          end
        end

        describe "activity filter" do
          context "when filtering by supported" do
            let(:activity) { "voted" }

            it "returns the fictions voted by the user" do
              create_list(:fiction, 3, component: component)
              create(:fiction_vote, fiction: Fiction.first, author: user)

              expect(subject.size).to eq(1)
            end
          end

          context "when filtering by my fictions" do
            let(:activity) { "my_fictions" }

            it "returns the fictions created by the user" do
              create_list(:fiction, 3, component: component)
              create(:fiction, component: component, users: [user])

              expect(subject.size).to eq(1)
            end
          end
        end

        describe "origin filter" do
          context "when filtering official fictions" do
            let(:origins) { %w(official) }

            it "returns only official fictions" do
              official_fictions = create_list(:fiction, 3, :official, component: component)
              create_list(:fiction, 3, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(official_fictions)
            end
          end

          context "when filtering citizen fictions" do
            let(:origins) { %w(citizens) }
            let(:another_user) { create(:user, organization: component.organization) }

            it "returns only citizen fictions" do
              create_list(:fiction, 3, :official, component: component)
              citizen_fictions = create_list(:fiction, 2, component: component)
              fiction.add_coauthor(another_user)
              citizen_fictions << fiction

              expect(subject.size).to eq(3)
              expect(subject).to match_array(citizen_fictions)
            end
          end

          context "when filtering user groups fictions" do
            let(:origins) { %w(user_group) }
            let(:user_group) { create :user_group, :verified, users: [user], organization: user.organization }

            it "returns only user groups fictions" do
              create(:fiction, :official, component: component)
              user_group_fiction = create(:fiction, component: component)
              user_group_fiction.coauthorships.clear
              user_group_fiction.add_coauthor(user, user_group: user_group)

              expect(subject.size).to eq(1)
              expect(subject).to eq([user_group_fiction])
            end
          end

          context "when filtering meetings fictions" do
            let(:origins) { %w(meeting) }
            let(:meeting) { create :meeting }

            it "returns only meeting fictions" do
              create(:fiction, :official, component: component)
              meeting_fiction = create(:fiction, :official_meeting, component: component)

              expect(subject.size).to eq(1)
              expect(subject).to eq([meeting_fiction])
            end
          end
        end

        describe "state filter" do
          context "when filtering for default states" do
            it "returns all except withdrawn fictions" do
              create_list(:fiction, 3, :withdrawn, component: component)
              other_fictions = create_list(:fiction, 3, component: component)
              other_fictions << fiction

              expect(subject.size).to eq(4)
              expect(subject).to match_array(other_fictions)
            end
          end

          context "when filtering :except_rejected fictions" do
            let(:states) { %w(accepted evaluating not_answered) }

            it "hides withdrawn and rejected fictions" do
              create(:fiction, :withdrawn, component: component)
              create(:fiction, :rejected, component: component)
              accepted_fiction = create(:fiction, :accepted, component: component)

              expect(subject.size).to eq(2)
              expect(subject).to match_array([accepted_fiction, fiction])
            end
          end

          context "when filtering accepted fictions" do
            let(:states) { %w(accepted) }

            it "returns only accepted fictions" do
              accepted_fictions = create_list(:fiction, 3, :accepted, component: component)
              create_list(:fiction, 3, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(accepted_fictions)
            end
          end

          context "when filtering rejected fictions" do
            let(:states) { %w(rejected) }

            it "returns only rejected fictions" do
              create_list(:fiction, 3, component: component)
              rejected_fictions = create_list(:fiction, 3, :rejected, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(rejected_fictions)
            end
          end

          context "when filtering withdrawn fictions" do
            let(:states) { %w(withdrawn) }

            it "returns only withdrawn fictions" do
              create_list(:fiction, 3, component: component)
              withdrawn_fictions = create_list(:fiction, 3, :withdrawn, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(withdrawn_fictions)
            end
          end
        end

        describe "scope_id filter" do
          let!(:fiction2) { create(:fiction, component: component, scope: scope2) }
          let!(:fiction3) { create(:fiction, component: component, scope: subscope1) }

          context "when a parent scope id is being sent" do
            let(:scope_ids) { [scope1.id] }

            it "filters fictions by scope" do
              expect(subject).to match_array [fiction, fiction3]
            end
          end

          context "when a subscope id is being sent" do
            let(:scope_ids) { [subscope1.id] }

            it "filters fictions by scope" do
              expect(subject).to eq [fiction3]
            end
          end

          context "when multiple ids are sent" do
            let(:scope_ids) { [scope2.id, scope1.id] }

            it "filters fictions by scope" do
              expect(subject).to match_array [fiction, fiction2, fiction3]
            end
          end

          context "when `global` is being sent" do
            let!(:resource_without_scope) { create(:fiction, component: component, scope: nil) }
            let(:scope_ids) { ["global"] }

            it "returns fictions without a scope" do
              expect(subject).to eq [resource_without_scope]
            end
          end

          context "when `global` and some ids is being sent" do
            let!(:resource_without_scope) { create(:fiction, component: component, scope: nil) }
            let(:scope_ids) { ["global", scope2.id, scope1.id] }

            it "returns fictions without a scope and with selected scopes" do
              expect(subject).to match_array [resource_without_scope, fiction, fiction2, fiction3]
            end
          end
        end

        describe "category_id filter" do
          let(:category1) { create :category, participatory_space: participatory_process }
          let(:category2) { create :category, participatory_space: participatory_process }
          let(:child_category) { create :category, participatory_space: participatory_process, parent: category2 }
          let!(:fiction2) { create(:fiction, component: component, category: category1) }
          let!(:fiction3) { create(:fiction, component: component, category: category2) }
          let!(:fiction4) { create(:fiction, component: component, category: child_category) }

          context "when no category filter is present" do
            it "includes all fictions" do
              expect(subject).to match_array [fiction, fiction2, fiction3, fiction4]
            end
          end

          context "when a category is selected" do
            let(:category_ids) { [category2.id] }

            it "includes only fictions for that category and its children" do
              expect(subject).to match_array [fiction3, fiction4]
            end
          end

          context "when a subcategory is selected" do
            let(:category_ids) { [child_category.id] }

            it "includes only fictions for that category" do
              expect(subject).to eq [fiction4]
            end
          end

          context "when `without` is being sent" do
            let(:category_ids) { ["without"] }

            it "returns fictions without a category" do
              expect(subject).to eq [fiction]
            end
          end

          context "when `without` and some category id is being sent" do
            let(:category_ids) { ["without", category1.id] }

            it "returns fictions without a category and with the selected category" do
              expect(subject).to match_array [fiction, fiction2]
            end
          end
        end

        describe "related_to filter" do
          context "when filtering by related to meetings" do
            let(:related_to) { "Decidim::Meetings::Meeting".underscore }
            let(:meetings_component) { create(:component, manifest_name: "meetings", participatory_space: participatory_process) }
            let(:meeting) { create :meeting, component: meetings_component }

            it "returns only fictions related to meetings" do
              related_fiction = create(:fiction, :accepted, component: component)
              related_fiction2 = create(:fiction, :accepted, component: component)
              create_list(:fiction, 3, component: component)
              meeting.link_resources([related_fiction], "fictions_from_meeting")
              related_fiction2.link_resources([meeting], "fictions_from_meeting")

              expect(subject).to match_array([related_fiction, related_fiction2])
            end
          end

          context "when filtering by related to resources" do
            let(:related_to) { "Decidim::DummyResources::DummyResource".underscore }
            let(:dummy_component) { create(:component, manifest_name: "dummy", participatory_space: participatory_process) }
            let(:dummy_resource) { create :dummy_resource, component: dummy_component }

            it "returns only fictions related to results" do
              related_fiction = create(:fiction, :accepted, component: component)
              related_fiction2 = create(:fiction, :accepted, component: component)
              create_list(:fiction, 3, component: component)
              dummy_resource.link_resources([related_fiction], "included_fictions")
              related_fiction2.link_resources([dummy_resource], "included_fictions")

              expect(subject).to match_array([related_fiction, related_fiction2])
            end
          end
        end
      end
    end
  end
end
