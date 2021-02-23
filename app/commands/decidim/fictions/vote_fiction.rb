# frozen_string_literal: true

module Decidim
  module Fictions
    # A command with all the business logic when a user votes a fiction.
    class VoteFiction < Rectify::Command
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
      # - :ok when everything is valid, together with the fiction vote.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if @fiction.maximum_votes_reached? && !@fiction.can_accumulate_supports_beyond_threshold

        build_fiction_vote
        return broadcast(:invalid) unless vote.valid?

        ActiveRecord::Base.transaction do
          @fiction.with_lock do
            vote.save!
            update_temporary_votes
          end
        end

        Decidim::Gamification.increment_score(@current_user, :fiction_votes)

        broadcast(:ok, vote)
      end

      attr_reader :vote

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
        return unless minimum_votes_per_user? && user_votes.count >= minimum_votes_per_user

        user_votes.each { |vote| vote.update(temporary: false) }
      end

      def user_votes
        @user_votes ||= FictionVote.where(
          author: @current_user,
          fiction: Fiction.where(component: component)
        )
      end

      def build_fiction_vote
        @vote = @fiction.votes.build(
          author: @current_user,
          temporary: minimum_votes_per_user?
        )
      end
    end
  end
end
