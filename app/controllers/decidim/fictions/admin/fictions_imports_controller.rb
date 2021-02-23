# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      class FictionsImportsController < Admin::ApplicationController
        def new
          enforce_permission_to :import, :fictions

          @form = form(Admin::FictionsImportForm).instance
        end

        def create
          enforce_permission_to :import, :fictions

          @form = form(Admin::FictionsImportForm).from_params(params)

          Admin::ImportFictions.call(@form) do
            on(:ok) do |fictions|
              flash[:notice] = I18n.t("fictions_imports.create.success", scope: "decidim.fictions.admin", number: fictions.length)
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("fictions_imports.create.invalid", scope: "decidim.fictions.admin")
              render action: "new"
            end
          end
        end
      end
    end
  end
end
