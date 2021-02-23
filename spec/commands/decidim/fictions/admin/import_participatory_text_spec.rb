# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    module Admin
      describe ImportParticipatoryText do
        describe "call" do
          let!(:document_file) { IO.read(Decidim::Dev.asset(document_name)) }
          let(:current_component) do
            create(
              :fiction_component,
              participatory_space: create(:participatory_process)
            )
          end
          let(:form_doc) do
            instance_double(File,
                            blank?: false)
          end
          let(:form) do
            instance_double(
              ImportParticipatoryTextForm,
              current_component: current_component,
              title: {},
              description: {},
              document: form_doc,
              document_text: document_file,
              document_type: document_type,
              current_user: create(:user),
              valid?: valid
            )
          end
          let(:command) { described_class.new(form) }

          shared_examples "import participatory_text succeeds" do
            let(:fictions) { Fiction.where(component: current_component) }

            it "broadcasts ok and creates the fictions" do
              levels = Decidim::Fictions::ParticipatoryTextSection::LEVELS
              sections = 2
              sub_sections = 5
              expect { command.call }.to(
                broadcast(:ok) &&
                change(fictions, :count).by(1) &&
                change { fictions.where(participatory_text_level: levels[:section]).count }.by(sections) &&
                change { fictions.where(participatory_text_level: levels[:sub_section]).count }.by(sub_sections) &&
                change { fictions.where(participatory_text_level: levels[:article]).count }.by(articles)
              )
            end

            it "does not create a version for each fiction", versioning: true do
              expect { command.call }.to broadcast(:ok)

              fictions.each do |fiction|
                expect(fiction.reload.versions.count).to be_zero
              end
            end
          end

          describe "when the form is not valid" do
            let(:valid) { false }
            let(:document_name) { "participatory_text.md" }
            let(:document_type) { "text/markdown" }

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't create any fiction" do
              expect do
                command.call
              end.to change(Fiction, :count).by(0)
            end
          end

          describe "when the form is valid" do
            let(:valid) { true }

            context "with markdown document" do
              let(:document_name) { "participatory_text.md" }
              let(:document_type) { "text/markdown" }
              let(:articles) { 15 }

              it_behaves_like "import participatory_text succeeds"
            end

            context "with odt document" do
              let(:document_name) { "participatory_text.odt" }
              let(:document_type) { "application/vnd.oasis.opendocument.text" }
              let(:articles) { 15 }

              it_behaves_like "import participatory_text succeeds"
            end

            context "with invalid odt document" do
              let(:document_name) { "participatory_text_wrong.odt" }
              let(:document_type) { "application/vnd.oasis.opendocument.text" }
              let(:articles) { 15 }

              it "broadcasts invalid_file" do
                expect { command.call }.to broadcast(:invalid_file)
              end
            end
          end
        end
      end
    end
  end
end
