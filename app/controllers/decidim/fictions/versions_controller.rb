# frozen_string_literal: true

module Decidim
  module Fictions
    # Exposes Fictions versions so users can see how a Fiction/CollaborativeDraft
    # has been updated through time.
    class VersionsController < Decidim::Fictions::ApplicationController
      include Decidim::ApplicationHelper
      include Decidim::ResourceVersionsConcern

      def versioned_resource
        @versioned_resource ||=
          if params[:fiction_id]
            present(Fiction.where(component: current_component).find(params[:fiction_id]))
          else
            CollaborativeDraft.where(component: current_component).find(params[:collaborative_draft_id])
          end
      end
    end
  end
end
