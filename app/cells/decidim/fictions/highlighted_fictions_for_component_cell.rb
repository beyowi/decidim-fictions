# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Fictions
    # This cell renders the highlighted fictions for a given component.
    # It is intended to be used in the `participatory_space_highlighted_elements`
    # view hook.
    class HighlightedFictionsForComponentCell < Decidim::ViewModel
      include Decidim::ComponentPathHelper

      def show
        render unless fictions_count.zero?
      end

      private

      def fictions
        @fictions ||= Decidim::Fictions::Fiction.published.not_hidden.except_withdrawn
                                                   .where(component: model)
                                                   .order_randomly(rand * 2 - 1)
      end

      def fictions_to_render
        @fictions_to_render ||= fictions.includes([:amendable, :category, :component, :scope]).limit(Decidim::Fictions.config.participatory_space_highlighted_fictions_limit)
      end

      def fictions_count
        @fictions_count ||= fictions.count
      end
    end
  end
end
