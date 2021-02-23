# frozen-string_literal: true

module Decidim
  module Fictions
    class FictionMentionedEvent < Decidim::Events::SimpleEvent
      include Decidim::ApplicationHelper

      i18n_attributes :mentioned_fiction_title

      private

      def mentioned_fiction_title
        present(mentioned_fiction).title
      end

      def mentioned_fiction
        @mentioned_fiction ||= Decidim::Fictions::Fiction.find(extra[:mentioned_fiction_id])
      end
    end
  end
end
