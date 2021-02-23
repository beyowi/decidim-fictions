# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A command with all the business logic related with an admin discarding participatory text fictions.
      class DiscardParticipatoryText < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A PreviewParticipatoryTextForm form object with the params.
        def initialize(component)
          @component = component
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          transaction do
            discard_drafts
          end

          broadcast(:ok)
        end

        private

        attr_reader :form

        def discard_drafts
          fictions = Decidim::Fictions::Fiction.drafts.where(component: @component)
          fictions.destroy_all
        end
      end
    end
  end
end
