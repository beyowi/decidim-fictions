# frozen_string_literal: true

module Decidim
  module Fictions
    # A fiction can include a notes created by admins.
    class FictionNote < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      belongs_to :fiction, foreign_key: "decidim_fiction_id", class_name: "Decidim::Fictions::Fiction", counter_cache: true
      belongs_to :author, foreign_key: "decidim_author_id", class_name: "Decidim::User"

      default_scope { order(created_at: :asc) }

      def self.log_presenter_class_for(_log)
        Decidim::Fictions::AdminLog::FictionNotePresenter
      end
    end
  end
end
