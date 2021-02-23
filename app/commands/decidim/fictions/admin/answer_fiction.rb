# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A command with all the business logic when an admin answers a fiction.
      class AnswerFiction < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        # fiction - The fiction to write the answer for.
        def initialize(form, fiction)
          @form = form
          @fiction = fiction
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          store_initial_fiction_state

          transaction do
            answer_fiction
            notify_fiction_answer
          end

          broadcast(:ok)
        end

        private

        attr_reader :form, :fiction, :initial_has_state_published, :initial_state

        def answer_fiction
          Decidim.traceability.perform_action!(
            "answer",
            fiction,
            form.current_user
          ) do
            attributes = {
              state: form.state,
              answer: form.answer,
              answered_at: Time.current,
              cost: form.cost,
              cost_report: form.cost_report,
              execution_period: form.execution_period
            }

            attributes[:state_published_at] = Time.current if !initial_has_state_published && form.publish_answer?

            fiction.update!(attributes)
          end
        end

        def notify_fiction_answer
          return if !initial_has_state_published && !form.publish_answer?

          NotifyFictionAnswer.call(fiction, initial_state)
        end

        def store_initial_fiction_state
          @initial_has_state_published = fiction.published_state?
          @initial_state = fiction.state
        end
      end
    end
  end
end
