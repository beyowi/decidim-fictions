# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    module Admin
      describe UpdateParticipatoryText do
        describe "call" do
          let(:current_component) do
            create(
              :fiction_component,
              participatory_space: create(:participatory_process)
            )
          end
          let(:fictions) do
            fictions = create_list(:fiction, 3, component: current_component)
            fictions.each_with_index do |fiction, idx|
              level = Decidim::Fictions::ParticipatoryTextSection::LEVELS.keys[idx]
              fiction.update(participatory_text_level: level)
              fiction.versions.destroy_all
            end
            fictions
          end
          let(:fiction_modifications) do
            modifs = []
            new_positions = [3, 1, 2]
            fictions.each do |fiction|
              modifs << Decidim::Fictions::Admin::FictionForm.new(
                id: fiction.id,
                position: new_positions.shift,
                title: ::Faker::Books::Lovecraft.fhtagn,
                body: ::Faker::Books::Lovecraft.fhtagn(5)
              )
            end
            modifs
          end
          let(:form) do
            instance_double(
              PreviewParticipatoryTextForm,
              current_component: current_component,
              fictions: fiction_modifications
            )
          end
          let(:command) { described_class.new(form) }

          it "does not create a version for each fiction", versioning: true do
            expect { command.call }.to broadcast(:ok)

            fictions.each do |fiction|
              expect(fiction.reload.versions.count).to be_zero
            end
          end

          describe "when form modifies fictions" do
            context "with valid values" do
              it "persists modifications" do
                expect { command.call }.to broadcast(:ok)
                fictions.zip(fiction_modifications).each do |fiction, fiction_form|
                  fiction.reload
                  actual = {}
                  expected = {}
                  %w(position title body).each do |attr|
                    next if (attr == "body") && (fiction.participatory_text_level != Decidim::Fictions::ParticipatoryTextSection::LEVELS[:article])

                    expected[attr] = fiction_form.send attr.to_sym
                    actual[attr] = fiction.attributes[attr]
                  end
                  expect(actual).to eq(expected)
                end
              end
            end

            context "with invalid values" do
              before do
                fiction_modifications.each { |fiction_form| fiction_form.title = "" }
              end

              it "does not persist modifications and broadcasts invalid" do
                failures = {}
                fictions.each do |fiction|
                  failures[fiction.id] = ["Title can't be blank"]
                end
                expect { command.call }.to broadcast(:invalid, failures)
              end
            end
          end
        end
      end
    end
  end
end
