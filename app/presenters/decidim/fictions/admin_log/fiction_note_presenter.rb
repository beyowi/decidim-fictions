# frozen_string_literal: true

module Decidim
  module Fictions
    module AdminLog
      # This class holds the logic to present a `Decidim::Fictions::FictionNote`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you shouldn't need to call this class
      # directly, but here's an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    FictionNotePresenter.new(action_log, view_helpers).present
      class FictionNotePresenter < Decidim::Log::BasePresenter
        private

        def diff_fields_mapping
          {
            body: :string
          }
        end

        def action_string
          case action
          when "create"
            "decidim.fictions.admin_log.fiction_note.#{action}"
          else
            super
          end
        end

        def i18n_labels_scope
          "activemodel.attributes.fiction_note"
        end
      end
    end
  end
end
