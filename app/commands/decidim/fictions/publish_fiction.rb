# frozen_string_literal: true

module Decidim
  module Fictions
    # A command with all the business logic when a user publishes a draft fiction.
    class PublishFiction < Rectify::Command
      # Public: Initializes the command.
      #
      # fiction     - The fiction to publish.
      # current_user - The current user.
      def initialize(fiction, current_user)
        @fiction = fiction
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid and the fiction is published.
      # - :invalid if the fiction's author is not the current user.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) unless @fiction.authored_by?(@current_user)

        transaction do
          publish_fiction
          increment_scores
          send_notification
          send_notification_to_participatory_space
        end

        broadcast(:ok, @fiction)
      end

      private

      # This will be the PaperTrail version that is
      # shown in the version control feature (1 of 1)
      #
      # For an attribute to appear in the new version it has to be reset
      # and reassigned, as PaperTrail only keeps track of object CHANGES.
      def publish_fiction
        title = reset(:title)
        body = reset(:body)

        Decidim.traceability.perform_action!(
          "publish",
          @fiction,
          @current_user,
          visibility: "public-only"
        ) do
          @fiction.update title: title, body: body, published_at: Time.current
        end
      end

      # Reset the attribute to an empty string and return the old value
      def reset(attribute)
        attribute_value = @fiction[attribute]
        PaperTrail.request(enabled: false) do
          # rubocop:disable Rails/SkipsModelValidations
          @fiction.update_attribute attribute, ""
          # rubocop:enable Rails/SkipsModelValidations
        end
        attribute_value
      end

      def send_notification
        return if @fiction.coauthorships.empty?

        Decidim::EventsManager.publish(
          event: "decidim.events.fictions.fiction_published",
          event_class: Decidim::Fictions::PublishFictionEvent,
          resource: @fiction,
          followers: coauthors_followers
        )
      end

      def send_notification_to_participatory_space
        Decidim::EventsManager.publish(
          event: "decidim.events.fictions.fiction_published",
          event_class: Decidim::Fictions::PublishFictionEvent,
          resource: @fiction,
          followers: @fiction.participatory_space.followers - coauthors_followers,
          extra: {
            participatory_space: true
          }
        )
      end

      def coauthors_followers
        @coauthors_followers ||= @fiction.authors.flat_map(&:followers)
      end

      def increment_scores
        @fiction.coauthorships.find_each do |coauthorship|
          if coauthorship.user_group
            Decidim::Gamification.increment_score(coauthorship.user_group, :fictions)
          else
            Decidim::Gamification.increment_score(coauthorship.author, :fictions)
          end
        end
      end
    end
  end
end
