# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # This controller allows admins to answer fictions in a participatory process.
      class FictionAnswersController < Admin::ApplicationController
        helper_method :fiction

        helper Fictions::ApplicationHelper
        helper Decidim::Fictions::Admin::FictionsHelper
        helper Decidim::Fictions::Admin::FictionRankingsHelper
        helper Decidim::Messaging::ConversationHelper

        def edit
          enforce_permission_to :create, :fiction_answer, fiction: fiction
          @form = form(Admin::FictionAnswerForm).from_model(fiction)
        end

        def update
          enforce_permission_to :create, :fiction_answer, fiction: fiction
          @notes_form = form(FictionNoteForm).instance
          @answer_form = form(Admin::FictionAnswerForm).from_params(params)

          Admin::AnswerFiction.call(@answer_form, fiction) do
            on(:ok) do
              flash[:notice] = I18n.t("fictions.answer.success", scope: "decidim.fictions.admin")
              redirect_to fictions_path
            end

            on(:invalid) do
              flash.keep[:alert] = I18n.t("fictions.answer.invalid", scope: "decidim.fictions.admin")
              render template: "decidim/fictions/admin/fictions/show"
            end
          end
        end

        private

        def skip_manage_component_permission
          true
        end

        def fiction
          @fiction ||= Fiction.where(component: current_component).find(params[:id])
        end
      end
    end
  end
end
