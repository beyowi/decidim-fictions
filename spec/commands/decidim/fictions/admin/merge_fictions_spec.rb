# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    module Admin
      describe MergeFictions do
        describe "call" do
          let!(:fictions) { create_list(:fiction, 3, component: current_component) }
          let!(:current_component) { create(:fiction_component) }
          let!(:target_component) { create(:fiction_component, participatory_space: current_component.participatory_space) }
          let(:form) do
            instance_double(
              FictionsMergeForm,
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

            it "creates a fiction in the new component" do
              expect do
                command.call
              end.to change { Fiction.where(component: target_component).count }.by(1)
            end

            it "links the fictions" do
              command.call
              fiction = Fiction.where(component: target_component).last

              linked = fiction.linked_resources(:fictions, "copied_from_component")

              expect(linked).to match_array(fictions)
            end

            it "only merges wanted attributes" do
              command.call
              new_fiction = Fiction.where(component: target_component).last
              fiction = fictions.first

              expect(new_fiction.title).to eq(fiction.title)
              expect(new_fiction.body).to eq(fiction.body)
              expect(new_fiction.creator_author).to eq(current_component.organization)
              expect(new_fiction.category).to eq(fiction.category)

              expect(new_fiction.state).to be_nil
              expect(new_fiction.answer).to be_nil
              expect(new_fiction.answered_at).to be_nil
              expect(new_fiction.reference).not_to eq(fiction.reference)
            end

            context "when merging from the same component" do
              let(:same_component) { true }
              let(:target_component) { current_component }

              it "deletes the original fictions" do
                command.call
                fiction_ids = fictions.map(&:id)

                expect(Decidim::Fictions::Fiction.where(id: fiction_ids)).to be_empty
              end

              it "links the merged fiction to the links the other fictions had" do
                other_component = create(:fiction_component, participatory_space: current_component.participatory_space)
                other_fictions = create_list(:fiction, 3, component: other_component)

                fictions.each_with_index do |fiction, index|
                  fiction.link_resources(other_fictions[index], "copied_from_component")
                end

                command.call

                fiction = Fiction.where(component: target_component).last
                linked = fiction.linked_resources(:fictions, "copied_from_component")
                expect(linked).to match_array(other_fictions)
              end
            end
          end
        end
      end
    end
  end
end
