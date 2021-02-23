# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # This class contains helpers needed to format Meetings
      # in order to use them in select forms for Fictions.
      #
      module FictionsHelper
        # Public: A formatted collection of Meetings to be used
        # in forms.
        def meetings_as_authors_selected
          return unless @fiction.present? && @fiction.official_meeting?

          @meetings_as_authors_selected ||= @fiction.authors.pluck(:id)
        end

        def coauthor_presenters_for(fiction)
          fiction.authors.map do |identity|
            if identity.is_a?(Decidim::Organization)
              Decidim::Fictions::OfficialAuthorPresenter.new
            else
              present(identity)
            end
          end
        end

        def endorsers_presenters_for(fiction)
          fiction.endorsements.for_listing.map { |identity| present(identity.normalized_author) }
        end

        def fiction_complete_state(fiction)
          state = humanize_fiction_state(fiction.state)
          state += " (#{humanize_fiction_state(fiction.internal_state)})" if fiction.answered? && !fiction.published_state?
          state.html_safe
        end

        def fictions_admin_filter_tree
          {
            t("fictions.filters.type", scope: "decidim.fictions") => {
              link_to(t("fictions", scope: "decidim.fictions.application_helper.filter_type_values"), q: ransak_params_for_query(is_emendation_true: "0"),
                                                                                                        per_page: per_page) => nil,
              link_to(t("amendments", scope: "decidim.fictions.application_helper.filter_type_values"), q: ransak_params_for_query(is_emendation_true: "1"),
                                                                                                         per_page: per_page) => nil
            },
            t("models.fiction.fields.state", scope: "decidim.fictions") =>
              Decidim::Fictions::Fiction::POSSIBLE_STATES.each_with_object({}) do |state, hash|
                if state == "not_answered"
                  hash[link_to((humanize_fiction_state state), q: ransak_params_for_query(state_null: 1), per_page: per_page)] = nil
                else
                  hash[link_to((humanize_fiction_state state), q: ransak_params_for_query(state_eq: state), per_page: per_page)] = nil
                end
              end,
            t("models.fiction.fields.category", scope: "decidim.fictions") => admin_filter_categories_tree(categories.first_class),
            t("fictions.filters.scope", scope: "decidim.fictions") => admin_filter_scopes_tree(current_component.organization.id)
          }
        end

        def fictions_admin_search_hidden_params
          return unless params[:q]

          tags = ""
          tags += hidden_field_tag "per_page", params[:per_page] if params[:per_page]
          tags += hidden_field_tag "q[is_emendation_true]", params[:q][:is_emendation_true] if params[:q][:is_emendation_true]
          tags += hidden_field_tag "q[state_eq]", params[:q][:state_eq] if params[:q][:state_eq]
          tags += hidden_field_tag "q[category_id_eq]", params[:q][:category_id_eq] if params[:q][:category_id_eq]
          tags += hidden_field_tag "q[scope_id_eq]", params[:q][:scope_id_eq] if params[:q][:scope_id_eq]
          tags.html_safe
        end

        def fictions_admin_filter_applied_filters
          html = []
          if params[:q][:is_emendation_true].present?
            html << content_tag(:span, class: "label secondary") do
              tag = "#{t("filters.type", scope: "decidim.fictions.fictions")}: "
              tag += if params[:q][:is_emendation_true].to_s == "1"
                       t("amendments", scope: "decidim.fictions.application_helper.filter_type_values")
                     else
                       t("fictions", scope: "decidim.fictions.application_helper.filter_type_values")
                     end
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:is_emendation_true), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:state_null]
            html << content_tag(:span, class: "label secondary") do
              tag = "#{t("models.fiction.fields.state", scope: "decidim.fictions")}: "
              tag += humanize_fiction_state "not_answered"
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:state_null), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:state_eq]
            html << content_tag(:span, class: "label secondary") do
              tag = "#{t("models.fiction.fields.state", scope: "decidim.fictions")}: "
              tag += humanize_fiction_state params[:q][:state_eq]
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:state_eq), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:category_id_eq]
            html << content_tag(:span, class: "label secondary") do
              tag = "#{t("models.fiction.fields.category", scope: "decidim.fictions")}: "
              tag += translated_attribute categories.find(params[:q][:category_id_eq]).name
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:category_id_eq), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:scope_id_eq]
            html << content_tag(:span, class: "label secondary") do
              tag = "#{t("models.fiction.fields.scope", scope: "decidim.fictions")}: "
              tag += translated_attribute Decidim::Scope.where(decidim_organization_id: current_component.organization.id).find(params[:q][:scope_id_eq]).name
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:scope_id_eq), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          html.join(" ").html_safe
        end

        def icon_with_link_to_fiction(fiction)
          icon, tooltip = if allowed_to?(:create, :fiction_answer, fiction: fiction) && !fiction.emendation?
                            [
                              "comment-square",
                              t(:answer_fiction, scope: "decidim.fictions.actions")
                            ]
                          else
                            [
                              "info",
                              t(:show, scope: "decidim.fictions.actions")
                            ]
                          end
          icon_link_to(icon, fiction_path(fiction), tooltip, class: "icon--small action-icon--show-fiction")
        end
      end
    end
  end
end
