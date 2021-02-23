# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # This class contains helpers needed to get rankings for a given fiction
      # ordered by some given criteria.
      #
      module FictionRankingsHelper
        # Public: Gets the ranking for a given fiction, ordered by some given
        # criteria. Fiction is sorted amongst its own siblings.
        #
        # Returns a Hash with two keys:
        #   :ranking - an Integer representing the ranking for the given fiction.
        #     Ranking starts with 1.
        #   :total - an Integer representing the total number of ranked fictions.
        #
        # Examples:
        #   ranking_for(fiction, fiction_votes_count: :desc)
        #   ranking_for(fiction, endorsements_count: :desc)
        def ranking_for(fiction, order = {})
          siblings = Decidim::Fictions::Fiction.where(component: fiction.component)
          ranked = siblings.order([order, id: :asc])
          ranked_ids = ranked.pluck(:id)

          { ranking: ranked_ids.index(fiction.id) + 1, total: ranked_ids.count }
        end

        # Public: Gets the ranking for a given fiction, ordered by endorsements.
        def endorsements_ranking_for(fiction)
          ranking_for(fiction, endorsements_count: :desc)
        end

        # Public: Gets the ranking for a given fiction, ordered by votes.
        def votes_ranking_for(fiction)
          ranking_for(fiction, fiction_votes_count: :desc)
        end

        def i18n_endorsements_ranking_for(fiction)
          rankings = endorsements_ranking_for(fiction)

          I18n.t(
            "ranking",
            scope: "decidim.fictions.admin.fictions.show",
            ranking: rankings[:ranking],
            total: rankings[:total]
          )
        end

        def i18n_votes_ranking_for(fiction)
          rankings = votes_ranking_for(fiction)

          I18n.t(
            "ranking",
            scope: "decidim.fictions.admin.fictions.show",
            ranking: rankings[:ranking],
            total: rankings[:total]
          )
        end
      end
    end
  end
end
