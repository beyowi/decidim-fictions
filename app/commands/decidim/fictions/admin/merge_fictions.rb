# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A command with all the business logic when an admin merges fictions from
      # one component to another.
      class MergeFictions < Rectify::Command
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

          broadcast(:ok, merge_fictions)
        end

        private

        attr_reader :form

        def merge_fictions
          transaction do
            merged_fiction = create_new_fiction
            merged_fiction.link_resources(fictions_to_link, "copied_from_component")
            form.fictions.each(&:destroy!) if form.same_component?
            merged_fiction
          end
        end

        def fictions_to_link
          return previous_links if form.same_component?

          form.fictions
        end

        def previous_links
          @previous_links ||= form.fictions.flat_map do |fiction|
            fiction.linked_resources(:fictions, "copied_from_component")
          end
        end

        def create_new_fiction
          original_fiction = form.fictions.first

          Decidim::Fictions::FictionBuilder.copy(
            original_fiction,
            author: form.current_organization,
            action_user: form.current_user,
            extra_attributes: {
              component: form.target_component
            },
            skip_link: true
          )
        end
      end
    end
  end
end
