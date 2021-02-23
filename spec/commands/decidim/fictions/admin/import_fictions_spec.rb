# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    module Admin
      describe ImportFictions do
        describe "call" do
          let!(:fiction) { create(:fiction, :accepted) }
          let(:keep_authors) { false }
          let(:current_component) do
            create(
              :fiction_component,
              participatory_space: fiction.component.participatory_space
            )
          end
          let(:form) do
            instance_double(
              FictionsImportForm,
              origin_component: fiction.component,
              current_component: current_component,
              current_organization: current_component.organization,
              keep_authors: keep_authors,
              states: states,
              current_user: create(:user),
              valid?: valid
            )
          end
          let(:states) { ["accepted"] }
          let(:command) { described_class.new(form) }

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

            it "creates the fictions" do
              expect do
                command.call
              end.to change { Fiction.where(component: current_component).count }.by(1)
            end

            context "when a fiction was already imported" do
              let(:second_fiction) { create(:fiction, :accepted, component: fiction.component) }

              before do
                command.call
                second_fiction
              end

              it "doesn't import it again" do
                expect do
                  command.call
                end.to change { Fiction.where(component: current_component).count }.by(1)

                titles = Fiction.where(component: current_component).map(&:title)
                expect(titles).to match_array([fiction.title, second_fiction.title])
              end
            end

            it "links the fictions" do
              command.call

              linked = fiction.linked_resources(:fictions, "copied_from_component")
              new_fiction = Fiction.where(component: current_component).last

              expect(linked).to include(new_fiction)
            end

            it "only imports wanted attributes" do
              command.call

              new_fiction = Fiction.where(component: current_component).last
              expect(new_fiction.title).to eq(fiction.title)
              expect(new_fiction.body).to eq(fiction.body)
              expect(new_fiction.creator_author).to eq(current_component.organization)
              expect(new_fiction.category).to eq(fiction.category)

              expect(new_fiction.state).to be_nil
              expect(new_fiction.answer).to be_nil
              expect(new_fiction.answered_at).to be_nil
              expect(new_fiction.reference).not_to eq(fiction.reference)
            end

            describe "when keep_authors is true" do
              let(:keep_authors) { true }

              it "only keeps the fiction authors" do
                command.call

                new_fiction = Fiction.where(component: current_component).last
                expect(new_fiction.title).to eq(fiction.title)
                expect(new_fiction.body).to eq(fiction.body)
                expect(new_fiction.creator_author).to eq(fiction.creator_author)
              end
            end

            describe "fiction states" do
              let(:states) { %w(not_answered rejected) }

              before do
                create(:fiction, :rejected, component: fiction.component)
                create(:fiction, component: fiction.component)
              end

              it "only imports fictions from the selected states" do
                expect do
                  command.call
                end.to change { Fiction.where(component: current_component).count }.by(2)

                expect(Fiction.where(component: current_component).pluck(:title)).not_to include(fiction.title)
              end
            end

            describe "when the fiction has attachments" do
              let!(:attachment) do
                create(:attachment, attached_to: fiction)
              end

              it "duplicates the attachments" do
                expect do
                  command.call
                end.to change(Attachment, :count).by(1)

                new_fiction = Fiction.where(component: current_component).last
                expect(new_fiction.attachments.count).to eq(1)
              end
            end
          end
        end
      end
    end
  end
end
