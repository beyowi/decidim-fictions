# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A command to notify about the change of the published state for a fiction.
      class NotifyFictionAnswer < Rectify::Command
        # Public: Initializes the command.
        #
        # fiction - The fiction to write the answer for.
        # initial_state - The fiction state before the current process.
        def initialize(fiction, initial_state)
          @fiction = fiction
          @initial_state = initial_state.to_s
        end

        # Executes the command. Broadcasts these events:
        #
        # - :noop when the answer is not published or the state didn't changed.
        # - :ok when everything is valid.
        #
        # Returns nothing.
        def call
          if fiction.published_state? && state_changed?
            transaction do
              increment_score
              notify_followers
            end
          end

          broadcast(:ok)
        end

        private

        attr_reader :fiction, :initial_state

        def state_changed?
          initial_state != fiction.state.to_s
        end

        def notify_followers
          if fiction.accepted?
            publish_event(
              "decidim.events.fictions.fiction_accepted",
              Decidim::Fictions::AcceptedFictionEvent
            )
          elsif fiction.rejected?
            publish_event(
              "decidim.events.fictions.fiction_rejected",
              Decidim::Fictions::RejectedFictionEvent
            )
          elsif fiction.evaluating?
            publish_event(
              "decidim.events.fictions.fiction_evaluating",
              Decidim::Fictions::EvaluatingFictionEvent
            )
          end
        end

        def publish_event(event, event_class)
          Decidim::EventsManager.publish(
            event: event,
            event_class: event_class,
            resource: fiction,
            affected_users: fiction.notifiable_identities,
            followers: fiction.followers - fiction.notifiable_identities
          )
        end

        def increment_score
          if fiction.accepted?
            fiction.coauthorships.find_each do |coauthorship|
              Decidim::Gamification.increment_score(coauthorship.user_group || coauthorship.author, :accepted_fictions)
            end
          elsif initial_state == "accepted"
            fiction.coauthorships.find_each do |coauthorship|
              Decidim::Gamification.decrement_score(coauthorship.user_group || coauthorship.author, :accepted_fictions)
            end
          end
        end
      end
    end
  end
end
