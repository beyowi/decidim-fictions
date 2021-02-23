# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A command with all the business logic to publish many answers at once.
      class PublishAnswers < Rectify::Command
        # Public: Initializes the command.
        #
        # component - The component that contains the answers.
        # user - the Decidim::User that is publishing the answers.
        # fiction_ids - the identifiers of the fictions with the answers to be published.
        def initialize(component, user, fiction_ids)
          @component = component
          @user = user
          @fiction_ids = fiction_ids
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if there are not fictions to publish.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless fictions.any?

          fictions.each do |fiction|
            transaction do
              mark_fiction_as_answered(fiction)
              notify_fiction_answer(fiction)
            end
          end

          broadcast(:ok)
        end

        private

        attr_reader :component, :user, :fiction_ids

        def fictions
          @fictions ||= Decidim::Fictions::Fiction
                         .published
                         .answered
                         .state_not_published
                         .where(component: component)
                         .where(id: fiction_ids)
        end

        def mark_fiction_as_answered(fiction)
          Decidim.traceability.perform_action!(
            "publish_answer",
            fiction,
            user
          ) do
            fiction.update!(state_published_at: Time.current)
          end
        end

        def notify_fiction_answer(fiction)
          NotifyFictionAnswer.call(fiction, nil)
        end
      end
    end
  end
end
