# frozen_string_literal: true

module Decidim
  module Fictions
    # Simple helpers to handle markup variations for fictions
    module FictionsHelper
      def fiction_reason_callout_args
        {
          announcement: {
            title: fiction_reason_callout_title,
            body: decidim_sanitize(translated_attribute(@fiction.answer))
          },
          callout_class: fiction_reason_callout_class
        }
      end

      def fiction_reason_callout_class
        case @fiction.state
        when "accepted"
          "success"
        when "evaluating"
          "warning"
        when "rejected"
          "alert"
        else
          ""
        end
      end

      def fiction_reason_callout_title
        i18n_key = case @fiction.state
                   when "evaluating"
                     "fiction_in_evaluation_reason"
                   else
                     "fiction_#{@fiction.state}_reason"
                   end

        t(i18n_key, scope: "decidim.fictions.fictions.show")
      end

      def filter_fictions_state_values
        Decidim::CheckBoxesTreeHelper::TreeNode.new(
          Decidim::CheckBoxesTreeHelper::TreePoint.new("", t("decidim.fictions.application_helper.filter_state_values.all")),
          [
            Decidim::CheckBoxesTreeHelper::TreePoint.new("accepted", t("decidim.fictions.application_helper.filter_state_values.accepted")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("evaluating", t("decidim.fictions.application_helper.filter_state_values.evaluating")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("not_answered", t("decidim.fictions.application_helper.filter_state_values.not_answered")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("rejected", t("decidim.fictions.application_helper.filter_state_values.rejected"))
          ]
        )
      end

      def fiction_has_costs?
        @fiction.cost.present? &&
          translated_attribute(@fiction.cost_report).present? &&
          translated_attribute(@fiction.execution_period).present?
      end

      def resource_version(resource, options = {})
        return unless resource.respond_to?(:amendable?) && resource.amendable?

        super
      end
    end
  end
end
