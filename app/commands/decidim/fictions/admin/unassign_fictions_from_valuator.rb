# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A command with all the business logic to unassign fictions from a given
      # valuator.
      class UnassignFictionsFromValuator < Rectify::Command
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

          unassign_fictions
          broadcast(:ok)
        end

        private

        attr_reader :form

        def unassign_fictions
          transaction do
            form.fictions.flat_map do |fiction|
              assignment = find_assignment(fiction)
              unassign(assignment) if assignment
            end
          end
        end

        def find_assignment(fiction)
          Decidim::Fictions::ValuationAssignment.find_by(
            fiction: fiction,
            valuator_role: form.valuator_role
          )
        end

        def unassign(assignment)
          Decidim.traceability.perform_action!(
            :delete,
            assignment,
            form.current_user,
            fiction_title: assignment.fiction.title
          ) do
            assignment.destroy!
          end
        end
      end
    end
  end
end
