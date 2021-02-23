# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    describe VoteFiction do
      describe "call" do
        let(:fiction) { create(:fiction) }
        let(:current_user) { create(:user, organization: fiction.component.organization) }
        let(:command) { described_class.new(fiction, current_user) }

        context "with normal conditions" do
          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "creates a new vote for the fiction" do
            expect do
              command.call
            end.to change(FictionVote, :count).by(1)
          end
        end

        context "when the vote is not valid" do
          before do
            # rubocop:disable RSpec/AnyInstance
            allow_any_instance_of(FictionVote).to receive(:valid?).and_return(false)
            # rubocop:enable RSpec/AnyInstance
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end

          it "doesn't create a new vote for the fiction" do
            expect do
              command.call
            end.to change(FictionVote, :count).by(0)
          end
        end

        context "when the threshold have been reached" do
          before do
            expect(fiction).to receive(:maximum_votes_reached?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end
        end

        context "when the threshold have been reached but fiction can accumulate more votes" do
          before do
            expect(fiction).to receive(:maximum_votes_reached?).and_return(true)
            expect(fiction).to receive(:can_accumulate_supports_beyond_threshold).and_return(true)
          end

          it "creates a new vote for the fiction" do
            expect do
              command.call
            end.to change(FictionVote, :count).by(1)
          end
        end
      end
    end
  end
end
