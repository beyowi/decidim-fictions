# frozen_string_literal: true

module Decidim
  module Fictions
    # Custom helpers, scoped to the fictions engine.
    #
    module ApplicationHelper
      include Decidim::Comments::CommentsHelper
      include PaginateHelper
      include FictionVotesHelper
      include ::Decidim::EndorsableHelper
      include ::Decidim::FollowableHelper
      include Decidim::MapHelper
      include Decidim::Fictions::MapHelper
      include CollaborativeDraftHelper
      include ControlVersionHelper
      include Decidim::RichTextEditorHelper
      include Decidim::CheckBoxesTreeHelper

      delegate :minimum_votes_per_user, to: :component_settings

      # Public: The state of a fiction in a way a human can understand.
      #
      # state - The String state of the fiction.
      #
      # Returns a String.
      def humanize_fiction_state(state)
        I18n.t(state, scope: "decidim.fictions.answers", default: :not_answered)
      end

      # Public: The css class applied based on the fiction state.
      #
      # state - The String state of the fiction.
      #
      # Returns a String.
      def fiction_state_css_class(state)
        case state
        when "accepted"
          "text-success"
        when "rejected"
          "text-alert"
        when "evaluating"
          "text-warning"
        when "withdrawn"
          "text-alert"
        else
          "text-info"
        end
      end

      # Public: The state of a fiction in a way a human can understand.
      #
      # state - The String state of the fiction.
      #
      # Returns a String.
      def humanize_collaborative_draft_state(state)
        I18n.t("decidim.fictions.collaborative_drafts.states.#{state}", default: :open)
      end

      # Public: The css class applied based on the collaborative draft state.
      #
      # state - The String state of the collaborative draft.
      #
      # Returns a String.
      def collaborative_draft_state_badge_css_class(state)
        case state
        when "open"
          "success"
        when "withdrawn"
          "alert"
        when "published"
          "secondary"
        end
      end

      def fiction_limit_enabled?
        fiction_limit.present?
      end

      def minimum_votes_per_user_enabled?
        minimum_votes_per_user.positive?
      end

      def not_from_collaborative_draft(fiction)
        fiction.linked_resources(:fictions, "created_from_collaborative_draft").empty?
      end

      def not_from_participatory_text(fiction)
        fiction.participatory_text_level.nil?
      end

      # If the fiction is official or the rich text editor is enabled on the
      # frontend, the fiction body is considered as safe content; that's unless
      # the fiction comes from a collaborative_draft or a participatory_text.
      def safe_content?
        rich_text_editor_in_public_views? && not_from_collaborative_draft(@fiction) ||
          (@fiction.official? || @fiction.official_meeting?) && not_from_participatory_text(@fiction)
      end

      # If the content is safe, HTML tags are sanitized, otherwise, they are stripped.
      def render_fiction_body(fiction)
        body = present(fiction).body(links: true, strip_tags: !safe_content?)
        body = simple_format(body, {}, sanitize: false)

        return body unless safe_content?

        decidim_sanitize(body)
      end

      # Returns :text_area or :editor based on the organization' settings.
      def text_editor_for_fiction_body(form)
        options = {
          class: "js-hashtags",
          hashtaggable: true,
          value: form_presenter.body(extras: false).strip
        }

        text_editor_for(form, :body, options)
      end

      def fiction_limit
        return if component_settings.fiction_limit.zero?

        component_settings.fiction_limit
      end

      def votes_given
        @votes_given ||= FictionVote.where(
          fiction: Fiction.where(component: current_component),
          author: current_user
        ).count
      end

      def votes_count_for(model, from_fictions_list)
        render partial: "decidim/fictions/fictions/participatory_texts/fiction_votes_count.html", locals: { fiction: model, from_fictions_list: from_fictions_list }
      end

      def vote_button_for(model, from_fictions_list)
        render partial: "decidim/fictions/fictions/participatory_texts/fiction_vote_button.html", locals: { fiction: model, from_fictions_list: from_fictions_list }
      end

      def endorsers_for(fiction)
        fiction.endorsements.for_listing.map { |identity| present(identity.normalized_author) }
      end

      def form_has_address?
        @form.address.present? || @form.has_address
      end

      def authors_for(collaborative_draft)
        collaborative_draft.identities.map { |identity| present(identity) }
      end

      def show_voting_rules?
        return false unless votes_enabled?

        return true if vote_limit_enabled?
        return true if threshold_per_fiction_enabled?
        return true if fiction_limit_enabled?
        return true if can_accumulate_supports_beyond_threshold?
        return true if minimum_votes_per_user_enabled?
      end

      def filter_type_values
        [
          ["all", t("decidim.fictions.application_helper.filter_type_values.all")],
          ["fictions", t("decidim.fictions.application_helper.filter_type_values.fictions")],
          ["amendments", t("decidim.fictions.application_helper.filter_type_values.amendments")]
        ]
      end

      # Options to filter Fictions by activity.
      def activity_filter_values
        base = [
          ["all", t(".all")],
          ["my_fictions", t(".my_fictions")]
        ]
        base += [["voted", t(".voted")]] if current_settings.votes_enabled?
        base
      end

      def filter_origin_values
        origin_values = []
        origin_values << TreePoint.new("official", t("decidim.fictions.application_helper.filter_origin_values.official")) if component_settings.official_fictions_enabled
        origin_values << TreePoint.new("citizens", t("decidim.fictions.application_helper.filter_origin_values.citizens"))
        origin_values << TreePoint.new("user_group", t("decidim.fictions.application_helper.filter_origin_values.user_groups")) if current_organization.user_groups_enabled?
        origin_values << TreePoint.new("meeting", t("decidim.fictions.application_helper.filter_origin_values.meetings"))

        TreeNode.new(
          TreePoint.new("", t("decidim.fictions.application_helper.filter_origin_values.all")),
          origin_values
        )
      end
    end
  end
end
