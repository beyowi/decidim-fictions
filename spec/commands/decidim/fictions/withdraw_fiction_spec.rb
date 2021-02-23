# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    describe WithdrawFiction do
      let(:fiction) { create(:fiction) }

      before do
        fiction.save!
      end

      describe "when current user IS the author of the fiction" do
        let(:current_user) { fiction.creator_author }
        let(:command) { described_class.new(fiction, current_user) }

        context "and the fiction has no supports" do
          it "withdraws the fiction" do
            expect do
              expect { command.call }.to broadcast(:ok)
            end.to change { Decidim::Fictions::Fiction.count }.by(0)
            expect(fiction.state).to eq("withdrawn")
          end
        end

        context "and the fiction HAS some supports" do
          before do
            fiction.votes.create!(author: current_user)
          end

          it "is not able to withdraw the fiction" do
            expect do
              expect { command.call }.to broadcast(:has_supports)
            end.to change { Decidim::Fictions::Fiction.count }.by(0)
            expect(fiction.state).not_to eq("withdrawn")
          end
        end
      end
    end
  end
end
