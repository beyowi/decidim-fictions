# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          # The public part needs to be implemented yet
          return permission_action if permission_action.scope != :admin

          # Valuators can only perform these actions
          if user_is_valuator?
            if valuator_assigned_to_fiction?
              can_create_fiction_note?
              can_create_fiction_answer?
            end
            can_export_fictions?
            valuator_can_unassign_valuator_from_fictions?

            return permission_action
          end

          if create_permission_action?
            can_create_fiction_note?
            can_create_fiction_from_admin?
            can_create_fiction_answer?
          end

          # Admins can only edit official fictions if they are within the
          # time limit.
          allow! if permission_action.subject == :fiction && permission_action.action == :edit && admin_edition_is_available?

          # Every user allowed by the space can update the category of the fiction
          allow! if permission_action.subject == :fiction_category && permission_action.action == :update

          # Every user allowed by the space can update the scope of the fiction
          allow! if permission_action.subject == :fiction_scope && permission_action.action == :update

          # Every user allowed by the space can import fictions from another_component
          allow! if permission_action.subject == :fictions && permission_action.action == :import

          # Every user allowed by the space can export fictions
          can_export_fictions?

          # Every user allowed by the space can merge fictions to another component
          allow! if permission_action.subject == :fictions && permission_action.action == :merge

          # Every user allowed by the space can split fictions to another component
          allow! if permission_action.subject == :fictions && permission_action.action == :split

          # Every user allowed by the space can assign fictions to a valuator
          allow! if permission_action.subject == :fictions && permission_action.action == :assign_to_valuator

          # Every user allowed by the space can unassign a valuator from fictions
          can_unassign_valuator_from_fictions?

          # Only admin users can publish many answers at once
          toggle_allow(user.admin?) if permission_action.subject == :fictions && permission_action.action == :publish_answers

          if permission_action.subject == :participatory_texts && participatory_texts_are_enabled?
            # Every user allowed by the space can manage (import, update and publish) participatory texts to fictions
            allow! if permission_action.action == :manage
          end

          permission_action
        end

        private

        def fiction
          @fiction ||= context.fetch(:fiction, nil)
        end

        def user_valuator_role
          @user_valuator_role ||= space.user_roles(:valuator).find_by(user: user)
        end

        def user_is_valuator?
          return if user.admin?

          user_valuator_role.present?
        end

        def valuator_assigned_to_fiction?
          @valuator_assigned_to_fiction ||=
            Decidim::Fictions::ValuationAssignment
            .where(fiction: fiction, valuator_role: user_valuator_role)
            .any?
        end

        def admin_creation_is_enabled?
          current_settings.try(:creation_enabled?) &&
            component_settings.try(:official_fictions_enabled)
        end

        def admin_edition_is_available?
          return unless fiction

          (fiction.official? || fiction.official_meeting?) && fiction.votes.empty?
        end

        def admin_fiction_answering_is_enabled?
          current_settings.try(:fiction_answering_enabled) &&
            component_settings.try(:fiction_answering_enabled)
        end

        def create_permission_action?
          permission_action.action == :create
        end

        def participatory_texts_are_enabled?
          component_settings.participatory_texts_enabled?
        end

        # There's no special condition to create fiction notes, only
        # users with access to the admin section can do it.
        def can_create_fiction_note?
          allow! if permission_action.subject == :fiction_note
        end

        # Fictions can only be created from the admin when the
        # corresponding setting is enabled.
        def can_create_fiction_from_admin?
          toggle_allow(admin_creation_is_enabled?) if permission_action.subject == :fiction
        end

        # Fictions can only be answered from the admin when the
        # corresponding setting is enabled.
        def can_create_fiction_answer?
          toggle_allow(admin_fiction_answering_is_enabled?) if permission_action.subject == :fiction_answer
        end

        def can_unassign_valuator_from_fictions?
          allow! if permission_action.subject == :fictions && permission_action.action == :unassign_from_valuator
        end

        def valuator_can_unassign_valuator_from_fictions?
          can_unassign_valuator_from_fictions? if user == context.fetch(:valuator, nil)
        end

        def can_export_fictions?
          allow! if permission_action.subject == :fictions && permission_action.action == :export
        end
      end
    end
  end
end
