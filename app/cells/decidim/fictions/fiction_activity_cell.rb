# frozen_string_literal: true

module Decidim
  module Fictions
    # A cell to display when a fiction has been published.
    class FictionActivityCell < ActivityCell
      def title
        I18n.t(
          "decidim.fictions.last_activity.new_fiction_at_html",
          link: participatory_space_link
        )
      end

      def resource_link_text
        decidim_html_escape(presenter.title)
      end

      def description
        strip_tags(presenter.body(links: true))
      end

      def presenter
        @presenter ||= Decidim::Fictions::FictionPresenter.new(resource)
      end
    end
  end
end
