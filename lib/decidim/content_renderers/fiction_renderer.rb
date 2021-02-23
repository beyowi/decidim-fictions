# frozen_string_literal: true

module Decidim
  module ContentRenderers
    # A renderer that searches Global IDs representing fictions in content
    # and replaces it with a link to their show page.
    #
    # e.g. gid://<APP_NAME>/Decidim::Fictions::Fiction/1
    #
    # @see BaseRenderer Examples of how to use a content renderer
    class FictionRenderer < BaseRenderer
      # Matches a global id representing a Decidim::User
      GLOBAL_ID_REGEX = %r{gid:\/\/([\w-]*\/Decidim::Fictions::Fiction\/(\d+))}i.freeze

      # Replaces found Global IDs matching an existing fiction with
      # a link to its show page. The Global IDs representing an
      # invalid Decidim::Fictions::Fiction are replaced with '???' string.
      #
      # @return [String] the content ready to display (contains HTML)
      def render
        content.gsub(GLOBAL_ID_REGEX) do |fiction_gid|
          fiction = GlobalID::Locator.locate(fiction_gid)
          Decidim::Fictions::FictionPresenter.new(fiction).display_mention
        rescue ActiveRecord::RecordNotFound
          fiction_id = fiction_gid.split("/").last
          "~#{fiction_id}"
        end
      end
    end
  end
end
