# frozen_string_literal: true

module Decidim
  module Fictions
    module AdminLog
      # This class holds the logic to present a `Decidim::Fictions::ValuationAssignment`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you shouldn't need to call this class
      # directly, but here's an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    ValuationAssignmentPresenter.new(action_log, view_helpers).present
      class ValuationAssignmentPresenter < Decidim::Log::BasePresenter
        private

        def resource_presenter
          @resource_presenter ||= Decidim::Fictions::Log::ValuationAssignmentPresenter.new(action_log.resource, h, action_log.extra["resource"])
        end

        def diff_fields_mapping
          {
            valuator_role_id: "Decidim::Fictions::AdminLog::ValueTypes::ValuatorRoleUserPresenter"
          }
        end

        def action_string
          case action
          when "create", "delete"
            "decidim.fictions.admin_log.valuation_assignment.#{action}"
          else
            super
          end
        end

        def i18n_labels_scope
          "activemodel.attributes.valuation_assignment.admin_log"
        end

        def has_diff?
          %w(create delete).include?(action) || super
        end

        def i18n_params
          super.merge(fiction_title: h.translated_attribute(action_log.extra["fiction_title"]))
        end
      end
    end
  end
end
