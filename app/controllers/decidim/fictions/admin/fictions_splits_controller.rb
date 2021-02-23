# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      class FictionsSplitsController < Admin::ApplicationController
        def create
          enforce_permission_to :split, :fictions

          @form = form(Admin::FictionsSplitForm).from_params(params)

          Admin::SplitFictions.call(@form) do
            on(:ok) do |_fiction|
              flash[:notice] = I18n.t("fictions_splits.create.success", scope: "decidim.fictions.admin")
              redirect_to EngineRouter.admin_proxy(@form.target_component).root_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("fictions_splits.create.invalid", scope: "decidim.fictions.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end
          end
        end
      end
    end
  end
end
