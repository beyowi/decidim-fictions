# frozen_string_literal: true

module Decidim
  module Fictions
    # A command with all the business logic when a user unvotes a fiction.
    class UnvoteFiction < Rectify::Command
      # Public: Initializes the command.
      #
      # fiction     - A Decidim::Fictions::Fiction object.
      # current_user - The current user.
      def initialize(fiction, current_user)
        @fiction = fiction
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the fiction.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        ActiveRecord::Base.transaction do
          FictionVote.where(
            author: @current_user,
            fiction: @fiction
          ).destroy_all

          update_temporary_votes
        end

        Decidim::Gamification.decrement_score(@current_user, :fiction_votes)

        broadcast(:ok, @fiction)
      end

      private

      def component
        @component ||= @fiction.component
      end

      def minimum_votes_per_user
        component.settings.minimum_votes_per_user
      end

      def minimum_votes_per_user?
        minimum_votes_per_user.positive?
      end

      def update_temporary_votes
        return unless minimum_votes_per_user? && user_votes.count < minimum_votes_per_user

        user_votes.each { |vote| vote.update(temporary: true) }
      end

      def user_votes
        @user_votes ||= FictionVote.where(
          author: @current_user,
          fiction: Fiction.where(component: component)
        )
      end
    end
  end
end
