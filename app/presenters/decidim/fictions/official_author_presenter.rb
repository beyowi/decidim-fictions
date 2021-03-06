# frozen_string_literal: true

module Decidim
  module Fictions
    #
    # A dummy presenter to abstract out the author of an official fiction.
    #
    class OfficialAuthorPresenter
      def name
        I18n.t("decidim.fictions.models.fiction.fields.official_fiction")
      end

      def nickname
        ""
      end

      def badge
        ""
      end

      def profile_path
        ""
      end

      def avatar_url
        ActionController::Base.helpers.asset_path("decidim/default-avatar.svg")
      end

      def deleted?
        false
      end

      def can_be_contacted?
        false
      end

      def has_tooltip?
        false
      end
    end
  end
end
