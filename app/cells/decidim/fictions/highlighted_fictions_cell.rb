# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Fictions
    # This cell renders the highlighted fictions for a given participatory
    # space. It is intended to be used in the `participatory_space_highlighted_elements`
    # view hook.
    class HighlightedFictionsCell < Decidim::ViewModel
      include FictionCellsHelper

      private

      def published_components
        Decidim::Component
          .where(
            participatory_space: model,
            manifest_name: :fictions
          )
          .published
      end
    end
  end
end
