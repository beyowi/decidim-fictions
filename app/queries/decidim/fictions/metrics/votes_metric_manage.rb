# frozen_string_literal: true

module Decidim
  module Fictions
    module Metrics
      class VotesMetricManage < Decidim::MetricManage
        def metric_name
          "votes"
        end

        def save
          cumulative.each do |key, cumulative_value|
            next if cumulative_value.zero?

            quantity_value = quantity[key] || 0
            category_id, space_type, space_id, fiction_id = key
            record = Decidim::Metric.find_or_initialize_by(day: @day.to_s, metric_type: @metric_name,
                                                           organization: @organization, decidim_category_id: category_id,
                                                           participatory_space_type: space_type, participatory_space_id: space_id,
                                                           related_object_type: "Decidim::Fictions::Fiction", related_object_id: fiction_id)
            record.assign_attributes(cumulative: cumulative_value, quantity: quantity_value)
            record.save!
          end
        end

        private

        def query
          return @query if @query

          spaces = Decidim.participatory_space_manifests.flat_map do |manifest|
            manifest.participatory_spaces.call(@organization).public_spaces
          end
          fiction_ids = Decidim::Fictions::Fiction.where(component: visible_component_ids_from_spaces(spaces.pluck(:id))).except_withdrawn.not_hidden.pluck(:id)
          @query = Decidim::Fictions::FictionVote.joins(fiction: :component)
                                                   .left_outer_joins(fiction: :category)
                                                   .where(fiction: fiction_ids)
          @query = @query.where("decidim_fictions_fiction_votes.created_at <= ?", end_time)
          @query = @query.group("decidim_categorizations.id",
                                :participatory_space_type,
                                :participatory_space_id,
                                :decidim_fiction_id)
          @query
        end

        def quantity
          @quantity ||= query.where("decidim_fictions_fiction_votes.created_at >= ?", start_time).count
        end
      end
    end
  end
end
