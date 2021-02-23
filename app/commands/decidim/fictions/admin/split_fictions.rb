# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A command with all the business logic when an admin splits fictions from
      # one component to another.
      class SplitFictions < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(form)
          @form = form
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless form.valid?

          broadcast(:ok, split_fictions)
        end

        private

        attr_reader :form

        def split_fictions
          transaction do
            form.fictions.flat_map do |original_fiction|
              # If copying to the same component we only need one copy
              # but linking to the original fiction links, not the
              # original fiction.
              create_fiction(original_fiction)
              create_fiction(original_fiction) unless form.same_component?
            end
          end
        end

        def create_fiction(original_fiction)
          split_fiction = Decidim::Fictions::FictionBuilder.copy(
            original_fiction,
            author: form.current_organization,
            action_user: form.current_user,
            extra_attributes: {
              component: form.target_component
            },
            skip_link: true
          )

          fictions_to_link = links_for(original_fiction)
          split_fiction.link_resources(fictions_to_link, "copied_from_component")
        end

        def links_for(fiction)
          return fiction unless form.same_component?

          fiction.linked_resources(:fictions, "copied_from_component")
        end
      end
    end
  end
end
