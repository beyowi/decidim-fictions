# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    module Admin
      describe DiscardParticipatoryText do
        describe "call" do
          let(:current_component) do
            create(
              :fiction_component,
              participatory_space: create(:participatory_process)
            )
          end
          let(:fictions) do
            create_list(:fiction, 3, :draft, component: current_component)
          end
          let(:command) { described_class.new(current_component) }

          describe "when discarding" do
            it "removes all drafts" do
              expect { command.call }.to broadcast(:ok)
              fictions = Decidim::Fictions::Fiction.drafts.where(component: current_component)
              expect(fictions).to be_empty
            end
          end
        end
      end
    end
  end
end
