# frozen_string_literal: true

module Decidim
  module Fictions
    # A collaborative_draft can accept requests to coauthor and contribute
    class CollaborativeDraftCollaboratorRequest < Fictions::ApplicationRecord
      validates :collaborative_draft, :user, presence: true

      belongs_to :collaborative_draft, class_name: "Decidim::Fictions::CollaborativeDraft", foreign_key: :decidim_fictions_collaborative_draft_id
      belongs_to :user, class_name: "Decidim::User", foreign_key: :decidim_user_id
    end
  end
end
