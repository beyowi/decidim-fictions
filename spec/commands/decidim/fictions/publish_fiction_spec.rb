# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    describe PublishFiction do
      describe "call" do
        let(:component) { create(:fiction_component) }
        let(:organization) { component.organization }
        let!(:current_user) { create(:user, organization: organization) }
        let(:follower) { create(:user, organization: organization) }
        let(:fiction_draft) { create(:fiction, :draft, component: component, users: [current_user]) }
        let!(:follow) { create :follow, followable: current_user, user: follower }

        it "broadcasts ok" do
          expect { described_class.call(fiction_draft, current_user) }.to broadcast(:ok)
        end

        it "scores on the fictions badge" do
          expect { described_class.call(fiction_draft, current_user) }.to change {
            Decidim::Gamification.status_for(current_user, :fictions).score
          }.by(1)
        end

        it "broadcasts invalid when the fiction is from another author" do
          expect { described_class.call(fiction_draft, follower) }.to broadcast(:invalid)
        end

        describe "events" do
          subject do
            described_class.new(fiction_draft, current_user)
          end

          it "notifies the fiction is published" do
            other_follower = create(:user, organization: organization)
            create(:follow, followable: component.participatory_space, user: follower)
            create(:follow, followable: component.participatory_space, user: other_follower)

            allow(Decidim::EventsManager).to receive(:publish)
              .with(hash_including(event: "decidim.events.gamification.badge_earned"))

            expect(Decidim::EventsManager)
              .to receive(:publish)
              .with(
                event: "decidim.events.fictions.fiction_published",
                event_class: Decidim::Fictions::PublishFictionEvent,
                resource: kind_of(Decidim::Fictions::Fiction),
                followers: [follower]
              )

            expect(Decidim::EventsManager)
              .to receive(:publish)
              .with(
                event: "decidim.events.fictions.fiction_published",
                event_class: Decidim::Fictions::PublishFictionEvent,
                resource: kind_of(Decidim::Fictions::Fiction),
                followers: [other_follower],
                extra: {
                  participatory_space: true
                }
              )

            subject.call
          end
        end
      end
    end
  end
end
