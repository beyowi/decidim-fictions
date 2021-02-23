# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      class FictionsMergesController < Admin::ApplicationController
        def create
          enforce_permission_to :merge, :fictions

          @form = form(Admin::FictionsMergeForm).from_params(params)

          Admin::MergeFictions.call(@form) do
            on(:ok) do |_fiction|
              flash[:notice] = I18n.t("fictions_merges.create.success", scope: "decidim.fictions.admin")
              redirect_to EngineRouter.admin_proxy(@form.target_component).root_path
            end

            on(:invalid) do
              flash[:alert] = I18n.t("fictions_merges.create.invalid", scope: "decidim.fictions.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end
          end
        end
      end
    end
  end
end
