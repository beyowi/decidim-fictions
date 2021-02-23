# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    describe UnvoteFiction do
      describe "call" do
        let(:fiction) { create(:fiction) }
        let(:current_user) { create(:user, organization: fiction.component.organization) }
        let!(:fiction_vote) { create(:fiction_vote, author: current_user, fiction: fiction) }
        let(:command) { described_class.new(fiction, current_user) }

        it "broadcasts ok" do
          expect { command.call }.to broadcast(:ok)
        end

        it "deletes the fiction vote for that user" do
          expect do
            command.call
          end.to change(FictionVote, :count).by(-1)
        end

        it "decrements the right score for that user" do
          Decidim::Gamification.set_score(current_user, :fiction_votes, 10)
          command.call
          expect(Decidim::Gamification.status_for(current_user, :fiction_votes).score).to eq(9)
        end
      end
    end
  end
end
