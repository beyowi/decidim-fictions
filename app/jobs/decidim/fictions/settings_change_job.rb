# frozen_string_literal: true

module Decidim
  module Fictions
    class SettingsChangeJob < ApplicationJob
      def perform(component_id, previous_settings, current_settings)
        component = Decidim::Component.find(component_id)

        if creation_enabled?(previous_settings, current_settings)
          event = "decidim.events.fictions.creation_enabled"
          event_class = Decidim::Fictions::CreationEnabledEvent
        elsif voting_enabled?(previous_settings, current_settings)
          event = "decidim.events.fictions.voting_enabled"
          event_class = Decidim::Fictions::VotingEnabledEvent
        elsif endorsing_enabled?(previous_settings, current_settings)
          event = "decidim.events.fictions.endorsing_enabled"
          event_class = Decidim::Fictions::EndorsingEnabledEvent
        end

        return unless event && event_class

        Decidim::EventsManager.publish(
          event: event,
          event_class: event_class,
          resource: component,
          followers: component.participatory_space.followers
        )
      end

      private

      # rubocop:disable Style/DoubleNegation
      def creation_enabled?(previous_settings, current_settings)
        current_settings[:creation_enabled] == true &&
          !!previous_settings[:creation_enabled] == false
      end

      def voting_enabled?(previous_settings, current_settings)
        (current_settings[:votes_enabled] == true && !!current_settings[:votes_blocked] == false) &&
          (!!previous_settings[:votes_enabled] == false || previous_settings[:votes_blocked] == true)
      end

      def endorsing_enabled?(previous_settings, current_settings)
        (current_settings[:endorsements_enabled] == true && !!current_settings[:endorsements_blocked] == false) &&
          (!!previous_settings[:endorsements_enabled] == false || previous_settings[:endorsements_blocked] == true)
      end
      # rubocop:enable Style/DoubleNegation
    end
  end
end
