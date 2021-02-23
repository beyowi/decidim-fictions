# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      #  A command with all the business logic when an admin batch updates fictions category.
      class UpdateFictionCategory < Rectify::Command
        # Public: Initializes the command.
        #
        # category_id - the category id to update
        # fiction_ids - the fictions ids to update.
        def initialize(category_id, fiction_ids)
          @category = Decidim::Category.find_by id: category_id
          @fiction_ids = fiction_ids
          @response = { category_name: "", successful: [], errored: [] }
        end

        # Executes the command. Broadcasts these events:
        #
        # - :update_fictions_category - when everything is ok, returns @response.
        # - :invalid_category - if the category is blank.
        # - :invalid_fiction_ids - if the fiction_ids is blank.
        #
        # Returns @response hash:
        #
        # - :category_name - the translated_name of the category assigned
        # - :successful - Array of names of the updated fictions
        # - :errored - Array of names of the fictions not updated because they already had the category assigned
        def call
          return broadcast(:invalid_category) if @category.blank?
          return broadcast(:invalid_fiction_ids) if @fiction_ids.blank?

          @response[:category_name] = @category.translated_name
          Fiction.where(id: @fiction_ids).find_each do |fiction|
            if @category == fiction.category
              @response[:errored] << fiction.title
            else
              transaction do
                update_fiction_category fiction
                notify_author fiction if fiction.coauthorships.any?
              end
              @response[:successful] << fiction.title
            end
          end

          broadcast(:update_fictions_category, @response)
        end

        private

        def update_fiction_category(fiction)
          fiction.update!(
            category: @category
          )
        end

        def notify_author(fiction)
          Decidim::EventsManager.publish(
            event: "decidim.events.fictions.fiction_update_category",
            event_class: Decidim::Fictions::Admin::UpdateFictionCategoryEvent,
            resource: fiction,
            affected_users: fiction.notifiable_identities
          )
        end
      end
    end
  end
end
