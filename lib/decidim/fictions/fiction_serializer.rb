# frozen_string_literal: true

module Decidim
  module Fictions
    # This class serializes a Fiction so can be exported to CSV, JSON or other
    # formats.
    class FictionSerializer < Decidim::Exporters::Serializer
      include Decidim::ApplicationHelper
      include Decidim::ResourceHelper
      include Decidim::TranslationsHelper

      # Public: Initializes the serializer with a fiction.
      def initialize(fiction)
        @fiction = fiction
      end

      # Public: Exports a hash with the serialized data for this fiction.
      def serialize
        {
          id: fiction.id,
          category: {
            id: fiction.category.try(:id),
            name: fiction.category.try(:name) || empty_translatable
          },
          scope: {
            id: fiction.scope.try(:id),
            name: fiction.scope.try(:name) || empty_translatable
          },
          participatory_space: {
            id: fiction.participatory_space.id,
            url: Decidim::ResourceLocatorPresenter.new(fiction.participatory_space).url
          },
          component: { id: component.id },
          title: present(fiction).title,
          body: present(fiction).body,
          state: fiction.state.to_s,
          reference: fiction.reference,
          answer: ensure_translatable(fiction.answer),
          supports: fiction.fiction_votes_count,
          endorsements: {
            total_count: fiction.endorsements.count,
            user_endorsements: user_endorsements
          },
          comments: fiction.comments.count,
          attachments: fiction.attachments.count,
          followers: fiction.followers.count,
          published_at: fiction.published_at,
          url: url,
          meeting_urls: meetings,
          related_fictions: related_fictions,
          is_amend: fiction.emendation?,
          original_fiction: {
            title: fiction&.amendable&.title,
            url: original_fiction_url
          }
        }
      end

      private

      attr_reader :fiction

      def component
        fiction.component
      end

      def meetings
        fiction.linked_resources(:meetings, "fictions_from_meeting").map do |meeting|
          Decidim::ResourceLocatorPresenter.new(meeting).url
        end
      end

      def related_fictions
        fiction.linked_resources(:fictions, "copied_from_component").map do |fiction|
          Decidim::ResourceLocatorPresenter.new(fiction).url
        end
      end

      def url
        Decidim::ResourceLocatorPresenter.new(fiction).url
      end

      def user_endorsements
        fiction.endorsements.for_listing.map { |identity| identity.normalized_author&.name }
      end

      def original_fiction_url
        return unless fiction.emendation? && fiction.amendable.present?

        Decidim::ResourceLocatorPresenter.new(fiction.amendable).url
      end
    end
  end
end
