# frozen_string_literal: true

module Decidim
  module Fictions
    class NotifyFictionsMentionedJob < ApplicationJob
      def perform(comment_id, linked_fictions)
        comment = Decidim::Comments::Comment.find(comment_id)

        linked_fictions.each do |fiction_id|
          fiction = Fiction.find(fiction_id)
          affected_users = fiction.notifiable_identities

          Decidim::EventsManager.publish(
            event: "decidim.events.fictions.fiction_mentioned",
            event_class: Decidim::Fictions::FictionMentionedEvent,
            resource: comment.root_commentable,
            affected_users: affected_users,
            extra: {
              comment_id: comment.id,
              mentioned_fiction_id: fiction_id
            }
          )
        end
      end
    end
  end
end
