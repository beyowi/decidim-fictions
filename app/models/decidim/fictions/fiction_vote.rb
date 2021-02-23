# frozen_string_literal: true

module Decidim
  module Fictions
    # A fiction can include a vote per user.
    class FictionVote < ApplicationRecord
      belongs_to :fiction, foreign_key: "decidim_fiction_id", class_name: "Decidim::Fictions::Fiction"
      belongs_to :author, foreign_key: "decidim_author_id", class_name: "Decidim::User"

      validates :fiction, uniqueness: { scope: :author }
      validate :author_and_fiction_same_organization
      validate :fiction_not_rejected

      after_save :update_fiction_votes_count
      after_destroy :update_fiction_votes_count

      # Temporary votes are used when a minimum amount of votes is configured in
      # a component. They aren't taken into account unless the amount of votes
      # exceeds a threshold - meanwhile, they're marked as temporary.
      def self.temporary
        where(temporary: true)
      end

      # Final votes are votes that will be taken into account, that is, they're
      # not temporary.
      def self.final
        where(temporary: false)
      end

      private

      def update_fiction_votes_count
        fiction.update_votes_count
      end

      # Private: check if the fiction and the author have the same organization
      def author_and_fiction_same_organization
        return if !fiction || !author

        errors.add(:fiction, :invalid) unless author.organization == fiction.organization
      end

      def fiction_not_rejected
        return unless fiction

        errors.add(:fiction, :invalid) if fiction.rejected?
      end
    end
  end
end
