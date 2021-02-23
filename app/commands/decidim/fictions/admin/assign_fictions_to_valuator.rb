# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A command with all the business logic to assign fictions to a given
      # valuator.
      class AssignFictionsToValuator < Rectify::Command
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

          assign_fictions
          broadcast(:ok)
        rescue ActiveRecord::RecordInvalid
          broadcast(:invalid)
        end

        private

        attr_reader :form

        def assign_fictions
          transaction do
            form.fictions.flat_map do |fiction|
              find_assignment(fiction) || assign_fiction(fiction)
            end
          end
        end

        def find_assignment(fiction)
          Decidim::Fictions::ValuationAssignment.find_by(
            fiction: fiction,
            valuator_role: form.valuator_role
          )
        end

        def assign_fiction(fiction)
          Decidim.traceability.create!(
            Decidim::Fictions::ValuationAssignment,
            form.current_user,
            fiction: fiction,
            valuator_role: form.valuator_role
          )
        end
      end
    end
  end
end
