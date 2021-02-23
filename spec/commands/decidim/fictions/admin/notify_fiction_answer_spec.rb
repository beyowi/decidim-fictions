# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    module Admin
      describe NotifyFictionAnswer do
        subject { command.call }

        let(:command) { described_class.new(fiction, initial_state) }
        let(:fiction) { create(:fiction, :accepted) }
        let(:initial_state) { nil }
        let(:current_user) { create(:user, :admin) }
        let(:follow) { create(:follow, followable: fiction, user: follower) }
        let(:follower) { create(:user, organization: fiction.organization) }

        before do
          follow

          # give fiction author initial points to avoid unwanted events during tests
          Decidim::Gamification.increment_score(fiction.creator_author, :accepted_fictions)
        end

        it "broadcasts ok" do
          expect { subject }.to broadcast(:ok)
        end

        it "notifies the fiction followers" do
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.fictions.fiction_accepted",
              event_class: Decidim::Fictions::AcceptedFictionEvent,
              resource: fiction,
              affected_users: match_array([fiction.creator_author]),
              followers: match_array([follower])
            )

          subject
        end

        it "increments the accepted fictions counter" do
          expect { subject }.to change { Gamification.status_for(fiction.creator_author, :accepted_fictions).score } .by(1)
        end

        context "when the fiction is rejected after being accepted" do
          let(:fiction) { create(:fiction, :rejected) }
          let(:initial_state) { "accepted" }

          it "broadcasts ok" do
            expect { subject }.to broadcast(:ok)
          end

          it "notifies the fiction followers" do
            expect(Decidim::EventsManager)
              .to receive(:publish)
              .with(
                event: "decidim.events.fictions.fiction_rejected",
                event_class: Decidim::Fictions::RejectedFictionEvent,
                resource: fiction,
                affected_users: match_array([fiction.creator_author]),
                followers: match_array([follower])
              )

            subject
          end

          it "decrements the accepted fictions counter" do
            expect { subject }.to change { Gamification.status_for(fiction.coauthorships.first.author, :accepted_fictions).score } .by(-1)
          end
        end

        context "when the fiction published state has not changed" do
          let(:initial_state) { "accepted" }

          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "doesn't notify the fiction followers" do
            expect(Decidim::EventsManager)
              .not_to receive(:publish)

            subject
          end

          it "doesn't modify the accepted fictions counter" do
            expect { subject }.not_to(change { Gamification.status_for(current_user, :accepted_fictions).score })
          end
        end
      end
    end
  end
end
