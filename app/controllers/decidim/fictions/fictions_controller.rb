# frozen_string_literal: true

module Decidim
  module Fictions
    # Exposes the fiction resource so users can view and create them.
    class FictionsController < Decidim::Fictions::ApplicationController
      helper Decidim::WidgetUrlsHelper
      helper FictionWizardHelper
      helper ParticipatoryTextsHelper
      include Decidim::ApplicationHelper
      include FormFactory
      include FilterResource
      include Decidim::Fictions::Orderable
      include Paginable

      helper_method :fiction_presenter, :form_presenter

      before_action :authenticate_user!, only: [:new, :create, :complete]
      before_action :ensure_is_draft, only: [:compare, :complete, :preview, :publish, :edit_draft, :update_draft, :destroy_draft]
      before_action :set_fiction, only: [:show, :edit, :update, :withdraw]
      before_action :edit_form, only: [:edit_draft, :edit]

      before_action :set_participatory_text

      def index
        if component_settings.participatory_texts_enabled?
          @fictions = Decidim::Fictions::Fiction
                       .where(component: current_component)
                       .published
                       .not_hidden
                       .only_amendables
                       .includes(:category, :scope)
                       .order(position: :asc)
          render "decidim/fictions/fictions/participatory_texts/participatory_text"
        else
          @fictions = search
                       .results
                       .published
                       .not_hidden
                       .includes(:amendable, :category, :component, :resource_permission, :scope)

          @voted_fictions = if current_user
                               FictionVote.where(
                                 author: current_user,
                                 fiction: @fictions.pluck(:id)
                               ).pluck(:decidim_fiction_id)
                             else
                               []
                             end
          @fictions = paginate(@fictions)
          @fictions = reorder(@fictions)
        end
      end

      def show
        raise ActionController::RoutingError, "Not Found" if @fiction.blank? || !can_show_fiction?

        @report_form = form(Decidim::ReportForm).from_params(reason: "spam")
      end

      def new
        enforce_permission_to :create, :fiction
        @step = :step_1
        if fiction_draft.present?
          redirect_to edit_draft_fiction_path(fiction_draft, component_id: fiction_draft.component.id, fiction_slug: fiction_draft.component.participatory_space.slug)
        else
          @form = form(FictionWizardCreateStepForm).from_params(body: translated_fiction_body_template)
        end
      end

      def create
        enforce_permission_to :create, :fiction
        @step = :step_1
        @form = form(FictionWizardCreateStepForm).from_params(fiction_creation_params)

        CreateFiction.call(@form, current_user) do
          on(:ok) do |fiction|
            flash[:notice] = I18n.t("fictions.create.success", scope: "decidim")

            redirect_to Decidim::ResourceLocatorPresenter.new(fiction).path + "/compare"
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("fictions.create.error", scope: "decidim")
            render :new
          end
        end
      end

      def compare
        @step = :step_2
        @similar_fictions ||= Decidim::Fictions::SimilarFictions
                               .for(current_component, @fiction)
                               .all

        if @similar_fictions.blank?
          flash[:notice] = I18n.t("fictions.fictions.compare.no_similars_found", scope: "decidim")
          redirect_to Decidim::ResourceLocatorPresenter.new(@fiction).path + "/complete"
        end
      end

      def complete
        enforce_permission_to :create, :fiction
        @step = :step_3

        @form = form_fiction_model

        @form.attachment = form_attachment_new
      end

      def preview
        @step = :step_4
      end

      def publish
        @step = :step_4
        PublishFiction.call(@fiction, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("fictions.publish.success", scope: "decidim")
            redirect_to fiction_path(@fiction)
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("fictions.publish.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def edit_draft
        @step = :step_3
        enforce_permission_to :edit, :fiction, fiction: @fiction
      end

      def update_draft
        @step = :step_1
        enforce_permission_to :edit, :fiction, fiction: @fiction

        @form = form_fiction_params
        UpdateFiction.call(@form, current_user, @fiction) do
          on(:ok) do |fiction|
            flash[:notice] = I18n.t("fictions.update_draft.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(fiction).path + "/preview"
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("fictions.update_draft.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def destroy_draft
        enforce_permission_to :edit, :fiction, fiction: @fiction

        DestroyFiction.call(@fiction, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("fictions.destroy_draft.success", scope: "decidim")
            redirect_to new_fiction_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("fictions.destroy_draft.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def edit
        enforce_permission_to :edit, :fiction, fiction: @fiction
      end

      def update
        enforce_permission_to :edit, :fiction, fiction: @fiction

        @form = form_fiction_params
        UpdateFiction.call(@form, current_user, @fiction) do
          on(:ok) do |fiction|
            flash[:notice] = I18n.t("fictions.update.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(fiction).path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("fictions.update.error", scope: "decidim")
            render :edit
          end
        end
      end

      def withdraw
        enforce_permission_to :withdraw, :fiction, fiction: @fiction

        WithdrawFiction.call(@fiction, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("fictions.update.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(@fiction).path
          end
          on(:has_supports) do
            flash[:alert] = I18n.t("fictions.withdraw.errors.has_supports", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(@fiction).path
          end
        end
      end

      private

      def search_klass
        FictionSearch
      end

      def default_filter_params
        {
          search_text: "",
          origin: default_filter_origin_params,
          activity: "all",
          category_id: default_filter_category_params,
          state: %w(accepted evaluating not_answered),
          scope_id: default_filter_scope_params,
          related_to: "",
          type: "all"
        }
      end

      def default_filter_origin_params
        filter_origin_params = %w(citizens meeting)
        filter_origin_params << "official" if component_settings.official_fictions_enabled
        filter_origin_params << "user_group" if current_organization.user_groups_enabled?
        filter_origin_params
      end

      def default_filter_category_params
        return "all" unless current_component.participatory_space.categories.any?

        ["all"] + current_component.participatory_space.categories.pluck(:id).map(&:to_s)
      end

      def default_filter_scope_params
        return "all" unless current_component.participatory_space.scopes.any?

        if current_component.participatory_space.scope
          ["all", current_component.participatory_space.scope.id] + current_component.participatory_space.scope.children.map { |scope| scope.id.to_s }
        else
          %w(all global) + current_component.participatory_space.scopes.pluck(:id).map(&:to_s)
        end
      end

      def fiction_draft
        Fiction.from_all_author_identities(current_user).not_hidden.only_amendables
                .where(component: current_component).find_by(published_at: nil)
      end

      def ensure_is_draft
        @fiction = Fiction.not_hidden.where(component: current_component).find(params[:id])
        redirect_to Decidim::ResourceLocatorPresenter.new(@fiction).path unless @fiction.draft?
      end

      def set_fiction
        @fiction = Fiction.published.not_hidden.where(component: current_component).find_by(id: params[:id])
      end

      # Returns true if the fiction is NOT an emendation or the user IS an admin.
      # Returns false if the fiction is not found or the fiction IS an emendation
      # and is NOT visible to the user based on the component's amendments settings.
      def can_show_fiction?
        return true if @fiction&.amendable? || current_user&.admin?

        Fiction.only_visible_emendations_for(current_user, current_component).published.include?(@fiction)
      end

      def fiction_presenter
        @fiction_presenter ||= present(@fiction)
      end

      def form_fiction_params
        form(FictionForm).from_params(params)
      end

      def form_fiction_model
        form(FictionForm).from_model(@fiction)
      end

      def form_presenter
        @form_presenter ||= present(@form, presenter_class: Decidim::Fictions::FictionPresenter)
      end

      def form_attachment_new
        form(AttachmentForm).from_model(Attachment.new)
      end

      def edit_form
        form_attachment_model = form(AttachmentForm).from_model(@fiction.attachments.first)
        @form = form_fiction_model
        @form.attachment = form_attachment_model
        @form
      end

      def set_participatory_text
        @participatory_text = Decidim::Fictions::ParticipatoryText.find_by(component: current_component)
      end

      def translated_fiction_body_template
        translated_attribute component_settings.new_fiction_body_template
      end

      def fiction_creation_params
        params[:fiction].merge(body_template: translated_fiction_body_template)
      end
    end
  end
end