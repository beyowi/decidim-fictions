# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # This controller allows admins to make private notes on fictions in a participatory process.
      class FictionNotesController < Admin::ApplicationController
        helper_method :fiction

        def create
          enforce_permission_to :create, :fiction_note, fiction: fiction
          @form = form(FictionNoteForm).from_params(params)

          CreateFictionNote.call(@form, fiction) do
            on(:ok) do
              flash[:notice] = I18n.t("fiction_notes.create.success", scope: "decidim.fictions.admin")
              redirect_to fiction_path(id: fiction.id)
            end

            on(:invalid) do
              flash.keep[:alert] = I18n.t("fiction_notes.create.error", scope: "decidim.fictions.admin")
              redirect_to fiction_path(id: fiction.id)
            end
          end
        end

        private

        def skip_manage_component_permission
          true
        end

        def fiction
          @fiction ||= Fiction.where(component: current_component).find(params[:fiction_id])
        end
      end
    end
  end
end
