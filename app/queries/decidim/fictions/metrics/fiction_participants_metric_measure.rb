# frozen_string_literal: true

module Decidim
  module Fictions
    module Metrics
      # Searches for Participants in the following actions
      #  - Create a fiction (Fictions)
      #  - Give support to a fiction (Fictions)
      #  - Endorse (Fictions)
      class FictionParticipantsMetricMeasure < Decidim::MetricMeasure
        def valid?
          super && @resource.is_a?(Decidim::Component)
        end

        def calculate
          cumulative_users = []
          cumulative_users |= retrieve_votes.pluck(:decidim_author_id)
          cumulative_users |= retrieve_endorsements.pluck(:decidim_author_id)
          cumulative_users |= retrieve_fictions.pluck("decidim_coauthorships.decidim_author_id") # To avoid ambiguosity must be called this way

          quantity_users = []
          quantity_users |= retrieve_votes(true).pluck(:decidim_author_id)
          quantity_users |= retrieve_endorsements(true).pluck(:decidim_author_id)
          quantity_users |= retrieve_fictions(true).pluck("decidim_coauthorships.decidim_author_id") # To avoid ambiguosity must be called this way

          {
            cumulative_users: cumulative_users.uniq,
            quantity_users: quantity_users.uniq
          }
        end

        private

        def retrieve_fictions(from_start = false)
          @fictions ||= Decidim::Fictions::Fiction.where(component: @resource).joins(:coauthorships)
                                                     .includes(:votes, :endorsements)
                                                     .where(decidim_coauthorships: {
                                                              decidim_author_type: [
                                                                "Decidim::UserBaseEntity",
                                                                "Decidim::Organization",
                                                                "Decidim::Meetings::Meeting"
                                                              ]
                                                            })
                                                     .where("decidim_fictions_fictions.published_at <= ?", end_time)
                                                     .except_withdrawn

          return @fictions.where("decidim_fictions_fictions.published_at >= ?", start_time) if from_start

          @fictions
        end

        def retrieve_votes(from_start = false)
          @votes ||= Decidim::Fictions::FictionVote.joins(:fiction).where(fiction: retrieve_fictions).joins(:author)
                                                     .where("decidim_fictions_fiction_votes.created_at <= ?", end_time)

          return @votes.where("decidim_fictions_fiction_votes.created_at >= ?", start_time) if from_start

          @votes
        end

        def retrieve_endorsements(from_start = false)
          @endorsements ||= Decidim::Endorsement.joins("INNER JOIN decidim_fictions_fictions fictions ON resource_id = fictions.id")
                                                .where(resource: retrieve_fictions)
                                                .where("decidim_endorsements.created_at <= ?", end_time)
                                                .where(decidim_author_type: "Decidim::UserBaseEntity")

          return @endorsements.where("decidim_endorsements.created_at >= ?", start_time) if from_start

          @endorsements
        end
      end
    end
  end
end
