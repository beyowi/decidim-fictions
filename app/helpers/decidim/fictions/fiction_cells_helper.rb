# frozen_string_literal: true

module Decidim
  module Fictions
    # Custom helpers, scoped to the fictions engine.
    #
    module FictionCellsHelper
      include Decidim::Fictions::ApplicationHelper
      include Decidim::Fictions::Engine.routes.url_helpers
      include Decidim::LayoutHelper
      include Decidim::ApplicationHelper
      include Decidim::TranslationsHelper
      include Decidim::ResourceReferenceHelper
      include Decidim::TranslatableAttributes
      include Decidim::CardHelper

      delegate :title, :state, :published_state?, :withdrawn?, :amendable?, :emendation?, to: :model

      def has_actions?
        return context[:has_actions] if context[:has_actions].present?

        fictions_controller? && index_action? && current_settings.votes_enabled? && !model.draft?
      end

      def has_footer?
        return context[:has_footer] if context[:has_footer].present?

        fictions_controller? && index_action? && current_settings.votes_enabled? && !model.draft?
      end

      def fictions_controller?
        context[:controller].class.to_s == "Decidim::Fictions::FictionsController"
      end

      def index_action?
        context[:controller].action_name == "index"
      end

      def current_settings
        model.component.current_settings
      end

      def component_settings
        model.component.settings
      end

      def current_component
        model.component
      end

      def from_context
        @options[:from]
      end

      def badge_name
        humanize_fiction_state state
      end

      def state_classes
        case state
        when "accepted"
          ["success"]
        when "rejected"
          ["alert"]
        when "evaluating"
          ["warning"]
        when "withdrawn"
          ["alert"]
        else
          ["muted"]
        end
      end
    end
  end
end
