# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      class ValuationAssignmentsController < Admin::ApplicationController
        def create
          enforce_permission_to :assign_to_valuator, :fictions

          @form = form(Admin::ValuationAssignmentForm).from_params(params)

          Admin::AssignFictionsToValuator.call(@form) do
            on(:ok) do |_fiction|
              flash[:notice] = I18n.t("valuation_assignments.create.success", scope: "decidim.fictions.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("valuation_assignments.create.invalid", scope: "decidim.fictions.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end
          end
        end

        def destroy
          @form = form(Admin::ValuationAssignmentForm).from_params(destroy_params)

          enforce_permission_to :unassign_from_valuator, :fictions, valuator: @form.valuator_user

          Admin::UnassignFictionsFromValuator.call(@form) do
            on(:ok) do |_fiction|
              flash.keep[:notice] = I18n.t("valuation_assignments.delete.success", scope: "decidim.fictions.admin")
              redirect_back fallback_location: EngineRouter.admin_proxy(current_component).root_path
            end

            on(:invalid) do
              flash.keep[:alert] = I18n.t("valuation_assignments.delete.invalid", scope: "decidim.fictions.admin")
              redirect_back fallback_location: EngineRouter.admin_proxy(current_component).root_path
            end
          end
        end

        private

        def destroy_params
          {
            id: params.dig(:valuator_role, :id) || params[:id],
            fiction_ids: params[:fiction_ids] || [params[:fiction_id]]
          }
        end

        def skip_manage_component_permission
          true
        end
      end
    end
  end
end
