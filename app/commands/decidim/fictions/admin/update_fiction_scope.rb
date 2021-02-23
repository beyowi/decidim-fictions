# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      #  A command with all the business logic when an admin batch updates fictions scope.
      class UpdateFictionScope < Rectify::Command
        include TranslatableAttributes
        # Public: Initializes the command.
        #
        # scope_id - the scope id to update
        # fiction_ids - the fictions ids to update.
        def initialize(scope_id, fiction_ids)
          @scope = Decidim::Scope.find_by id: scope_id
          @fiction_ids = fiction_ids
          @response = { scope_name: "", successful: [], errored: [] }
        end

        # Executes the command. Broadcasts these events:
        #
        # - :update_fictions_scope - when everything is ok, returns @response.
        # - :invalid_scope - if the scope is blank.
        # - :invalid_fiction_ids - if the fiction_ids is blank.
        #
        # Returns @response hash:
        #
        # - :scope_name - the translated_name of the scope assigned
        # - :successful - Array of names of the updated fictions
        # - :errored - Array of names of the fictions not updated because they already had the scope assigned
        def call
          return broadcast(:invalid_scope) if @scope.blank?
          return broadcast(:invalid_fiction_ids) if @fiction_ids.blank?

          update_fictions_scope

          broadcast(:update_fictions_scope, @response)
        end

        private

        attr_reader :scope, :fiction_ids

        def update_fictions_scope
          @response[:scope_name] = translated_attribute(scope.name, scope.organization)
          Fiction.where(id: fiction_ids).find_each do |fiction|
            if scope == fiction.scope
              @response[:errored] << fiction.title
            else
              transaction do
                update_fiction_scope fiction
                notify_author fiction if fiction.coauthorships.any?
              end
              @response[:successful] << fiction.title
            end
          end
        end

        def update_fiction_scope(fiction)
          fiction.update!(
            scope: scope
          )
        end

        def notify_author(fiction)
          Decidim::EventsManager.publish(
            event: "decidim.events.fictions.fiction_update_scope",
            event_class: Decidim::Fictions::Admin::UpdateFictionScopeEvent,
            resource: fiction,
            affected_users: fiction.notifiable_identities
          )
        end
      end
    end
  end
end
