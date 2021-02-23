# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A command with all the business logic when an admin updates participatory text fictions.
      class UpdateParticipatoryText < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A PreviewParticipatoryTextForm form object with the params.
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
          transaction do
            @failures = {}
            update_contents_and_resort_fictions(form)
          end

          if @failures.any?
            broadcast(:invalid, @failures)
          else
            broadcast(:ok)
          end
        end

        private

        attr_reader :form

        # Prevents PaperTrail from creating versions while updating participatory text fictions.
        # A first version will be created when publishing the Participatory Text.
        def update_contents_and_resort_fictions(form)
          PaperTrail.request(enabled: false) do
            form.fictions.each do |prop_form|
              fiction = Fiction.where(component: form.current_component).find(prop_form.id)
              fiction.set_list_position(prop_form.position) if fiction.position != prop_form.position
              fiction.title = prop_form.title
              fiction.body = prop_form.body if fiction.participatory_text_level == ParticipatoryTextSection::LEVELS[:article]

              add_failure(fiction) unless fiction.save
            end
          end
          raise ActiveRecord::Rollback if @failures.any?
        end

        def add_failure(fiction)
          @failures[fiction.id] = fiction.errors.full_messages
        end
      end
    end
  end
end
