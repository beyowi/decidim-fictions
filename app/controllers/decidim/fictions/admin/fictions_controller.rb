# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # This controller allows admins to manage fictions in a participatory process.
      class FictionsController < Admin::ApplicationController
        include Decidim::ApplicationHelper
        include Decidim::Fictions::Admin::Filterable

        helper Fictions::ApplicationHelper
        helper Decidim::Fictions::Admin::FictionRankingsHelper
        helper Decidim::Messaging::ConversationHelper
        helper_method :fictions, :query, :form_presenter, :fiction, :fiction_ids
        helper Fictions::Admin::FictionBulkActionsHelper

        def show
          @notes_form = form(FictionNoteForm).instance
          @answer_form = form(Admin::FictionAnswerForm).from_model(fiction)
        end

        def new
          enforce_permission_to :create, :fiction
          @form = form(Admin::FictionForm).from_params(
            attachment: form(AttachmentForm).from_params({})
          )
        end

        def create
          enforce_permission_to :create, :fiction
          @form = form(Admin::FictionForm).from_params(params)

          Admin::CreateFiction.call(@form) do
            on(:ok) do
              flash[:notice] = I18n.t("fictions.create.success", scope: "decidim.fictions.admin")
              redirect_to fictions_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("fictions.create.invalid", scope: "decidim.fictions.admin")
              render action: "new"
            end
          end
        end

        def update_category
          enforce_permission_to :update, :fiction_category

          Admin::UpdateFictionCategory.call(params[:category][:id], fiction_ids) do
            on(:invalid_category) do
              flash.now[:error] = I18n.t(
                "fictions.update_category.select_a_category",
                scope: "decidim.fictions.admin"
              )
            end

            on(:invalid_fiction_ids) do
              flash.now[:alert] = I18n.t(
                "fictions.update_category.select_a_fiction",
                scope: "decidim.fictions.admin"
              )
            end

            on(:update_fictions_category) do
              flash.now[:notice] = update_fictions_bulk_response_successful(@response, :category)
              flash.now[:alert] = update_fictions_bulk_response_errored(@response, :category)
            end
            respond_to do |format|
              format.js
            end
          end
        end

        def publish_answers
          enforce_permission_to :publish_answers, :fictions

          Decidim::Fictions::Admin::PublishAnswers.call(current_component, current_user, fiction_ids) do
            on(:invalid) do
              flash.now[:alert] = t(
                "fictions.publish_answers.select_a_fiction",
                scope: "decidim.fictions.admin"
              )
            end

            on(:ok) do
              flash.now[:notice] = I18n.t("fictions.publish_answers.success", scope: "decidim")
            end
          end

          respond_to do |format|
            format.js
          end
        end

        def update_scope
          enforce_permission_to :update, :fiction_scope

          Admin::UpdateFictionScope.call(params[:scope_id], fiction_ids) do
            on(:invalid_scope) do
              flash.now[:error] = t(
                "fictions.update_scope.select_a_scope",
                scope: "decidim.fictions.admin"
              )
            end

            on(:invalid_fiction_ids) do
              flash.now[:alert] = t(
                "fictions.update_scope.select_a_fiction",
                scope: "decidim.fictions.admin"
              )
            end

            on(:update_fictions_scope) do
              flash.now[:notice] = update_fictions_bulk_response_successful(@response, :scope)
              flash.now[:alert] = update_fictions_bulk_response_errored(@response, :scope)
            end

            respond_to do |format|
              format.js
            end
          end
        end

        def edit
          enforce_permission_to :edit, :fiction, fiction: fiction
          @form = form(Admin::FictionForm).from_model(fiction)
          @form.attachment = form(AttachmentForm).from_params({})
        end

        def update
          enforce_permission_to :edit, :fiction, fiction: fiction

          @form = form(Admin::FictionForm).from_params(params)
          Admin::UpdateFiction.call(@form, @fiction) do
            on(:ok) do |_fiction|
              flash[:notice] = t("fictions.update.success", scope: "decidim")
              redirect_to fictions_path
            end

            on(:invalid) do
              flash.now[:alert] = t("fictions.update.error", scope: "decidim")
              render :edit
            end
          end
        end

        private

        def collection
          @collection ||= Fiction.where(component: current_component).published
        end

        def fictions
          @fictions ||= filtered_collection
        end

        def fiction
          @fiction ||= collection.find(params[:id])
        end

        def fiction_ids
          @fiction_ids ||= params[:fiction_ids]
        end

        def update_fictions_bulk_response_successful(response, subject)
          return if response[:successful].blank?

          if subject == :category
            t(
              "fictions.update_category.success",
              subject_name: response[:subject_name],
              fictions: response[:successful].to_sentence,
              scope: "decidim.fictions.admin"
            )
          elsif subject == :scope
            t(
              "fictions.update_scope.success",
              subject_name: response[:subject_name],
              fictions: response[:successful].to_sentence,
              scope: "decidim.fictions.admin"
            )
          end
        end

        def update_fictions_bulk_response_errored(response, subject)
          return if response[:errored].blank?

          if subject == :category
            t(
              "fictions.update_category.invalid",
              subject_name: response[:subject_name],
              fictions: response[:errored].to_sentence,
              scope: "decidim.fictions.admin"
            )
          elsif subject == :scope
            t(
              "fictions.update_scope.invalid",
              subject_name: response[:subject_name],
              fictions: response[:errored].to_sentence,
              scope: "decidim.fictions.admin"
            )
          end
        end

        def form_presenter
          @form_presenter ||= present(@form, presenter_class: Decidim::Fictions::FictionPresenter)
        end
      end
    end
  end
end
