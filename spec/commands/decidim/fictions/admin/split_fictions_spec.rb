# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    module Admin
      describe SplitFictions do
        describe "call" do
          let!(:fictions) { Array(create(:fiction, component: current_component)) }
          let!(:current_component) { create(:fiction_component) }
          let!(:target_component) { create(:fiction_component, participatory_space: current_component.participatory_space) }
          let(:form) do
            instance_double(
              FictionsSplitForm,
              current_component: current_component,
              current_organization: current_component.organization,
              target_component: target_component,
              fictions: fictions,
              valid?: valid,
              same_component?: same_component,
              current_user: create(:user, :admin, organization: current_component.organization)
            )
          end
          let(:command) { described_class.new(form) }
          let(:same_component) { false }

          describe "when the form is not valid" do
            let(:valid) { false }

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't create the fiction" do
              expect do
                command.call
              end.to change(Fiction, :count).by(0)
            end
          end

          describe "when the form is valid" do
            let(:valid) { true }

            it "broadcasts ok" do
              expect { command.call }.to broadcast(:ok)
            end

            it "creates two fictions for each original in the new component" do
              expect do
                command.call
              end.to change { Fiction.where(component: target_component).count }.by(2)
            end

            it "links the fictions" do
              command.call
              new_fictions = Fiction.where(component: target_component)

              linked = fictions.first.linked_resources(:fictions, "copied_from_component")

              expect(linked).to match_array(new_fictions)
            end

            it "only copies wanted attributes" do
              command.call
              fiction = fictions.first
              new_fiction = Fiction.where(component: target_component).last

              expect(new_fiction.title).to eq(fiction.title)
              expect(new_fiction.body).to eq(fiction.body)
              expect(new_fiction.creator_author).to eq(current_component.organization)
              expect(new_fiction.category).to eq(fiction.category)

              expect(new_fiction.state).to be_nil
              expect(new_fiction.answer).to be_nil
              expect(new_fiction.answered_at).to be_nil
              expect(new_fiction.reference).not_to eq(fiction.reference)
            end

            context "when spliting to the same component" do
              let(:same_component) { true }
              let!(:target_component) { current_component }
              let!(:fictions) { create_list(:fiction, 2, component: current_component) }

              it "only creates one copy for each fiction" do
                expect do
                  command.call
                end.to change { Fiction.where(component: current_component).count }.by(2)
              end

              context "when the original fiction has links to other fictions" do
                let(:previous_component) { create(:fiction_component, participatory_space: current_component.participatory_space) }
                let(:previous_fictions) { create(:fiction, component: previous_component) }

                before do
                  fictions.each do |fiction|
                    fiction.link_resources(previous_fictions, "copied_from_component")
                  end
                end

                it "links the copy to the same links the fiction has" do
                  new_fictions = Fiction.where(component: target_component).last(2)

                  new_fictions.each do |fiction|
                    linked = fiction.linked_resources(:fictions, "copied_from_component")
                    expect(linked).to eq([previous_fictions])
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
