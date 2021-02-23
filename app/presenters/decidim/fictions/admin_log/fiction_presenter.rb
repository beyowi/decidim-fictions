# frozen_string_literal: true

module Decidim
  module Fictions
    module AdminLog
      # This class holds the logic to present a `Decidim::Fictions::Fiction`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you shouldn't need to call this class
      # directly, but here's an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    FictionPresenter.new(action_log, view_helpers).present
      class FictionPresenter < Decidim::Log::BasePresenter
        private

        def resource_presenter
          @resource_presenter ||= Decidim::Fictions::Log::ResourcePresenter.new(action_log.resource, h, action_log.extra["resource"])
        end

        def diff_fields_mapping
          {
            title: "Decidim::Fictions::AdminLog::ValueTypes::FictionTitleBodyPresenter",
            body: "Decidim::Fictions::AdminLog::ValueTypes::FictionTitleBodyPresenter",
            state: "Decidim::Fictions::AdminLog::ValueTypes::FictionStatePresenter",
            answered_at: :date,
            answer: :i18n
          }
        end

        def action_string
          case action
          when "answer", "create", "update", "publish_answer"
            "decidim.fictions.admin_log.fiction.#{action}"
          else
            super
          end
        end

        def i18n_labels_scope
          "activemodel.attributes.fiction"
        end

        def has_diff?
          action == "answer" || super
        end
      end
    end
  end
end
