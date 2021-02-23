# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A command with all the business logic when an admin imports fictions from
      # one component to another.
      class ImportFictions < Rectify::Command
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

          broadcast(:ok, import_fictions)
        end

        private

        attr_reader :form

        def import_fictions
          fictions.map do |original_fiction|
            next if fiction_already_copied?(original_fiction, target_component)

            Decidim::Fictions::FictionBuilder.copy(
              original_fiction,
              author: fiction_author,
              action_user: form.current_user,
              extra_attributes: {
                "component" => target_component
              }
            )
          end.compact
        end

        def fictions
          Decidim::Fictions::Fiction
            .where(component: origin_component)
            .where(state: fiction_states)
        end

        def fiction_states
          @fiction_states = @form.states

          if @form.states.include?("not_answered")
            @fiction_states.delete("not_answered")
            @fiction_states.push(nil)
          end

          @fiction_states
        end

        def origin_component
          @form.origin_component
        end

        def target_component
          @form.current_component
        end

        def fiction_already_copied?(original_fiction, target_component)
          original_fiction.linked_resources(:fictions, "copied_from_component").any? do |fiction|
            fiction.component == target_component
          end
        end

        def fiction_author
          form.keep_authors ? nil : @form.current_organization
        end
      end
    end
  end
end
