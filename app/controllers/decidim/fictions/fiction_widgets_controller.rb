# frozen_string_literal: true

module Decidim
  module Fictions
    class FictionWidgetsController < Decidim::WidgetsController
      helper Fictions::ApplicationHelper

      private

      def model
        @model ||= Fiction.where(component: params[:component_id]).find(params[:fiction_id])
      end

      def iframe_url
        @iframe_url ||= fiction_fiction_widget_url(model)
      end
    end
  end
end
