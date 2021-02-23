# frozen_string_literal: true

module Decidim
  module Fictions
    # Exposes the fiction vote resource so users can vote fictions.
    class FictionVotesController < Decidim::Fictions::ApplicationController
      include FictionVotesHelper
      include Rectify::ControllerHelpers

      helper_method :fiction

      before_action :authenticate_user!

      def create
        enforce_permission_to :vote, :fiction, fiction: fiction
        @from_fictions_list = params[:from_fictions_list] == "true"

        VoteFiction.call(fiction, current_user) do
          on(:ok) do
            fiction.reload

            fictions = FictionVote.where(
              author: current_user,
              fiction: Fiction.where(component: current_component)
            ).map(&:fiction)

            expose(fictions: fictions)
            render :update_buttons_and_counters
          end

          on(:invalid) do
            render json: { error: I18n.t("fiction_votes.create.error", scope: "decidim.fictions") }, status: :unprocessable_entity
          end
        end
      end

      def destroy
        enforce_permission_to :unvote, :fiction, fiction: fiction
        @from_fictions_list = params[:from_fictions_list] == "true"

        UnvoteFiction.call(fiction, current_user) do
          on(:ok) do
            fiction.reload

            fictions = FictionVote.where(
              author: current_user,
              fiction: Fiction.where(component: current_component)
            ).map(&:fiction)

            expose(fictions: fictions + [fiction])
            render :update_buttons_and_counters
          end
        end
      end

      private

      def fiction
        @fiction ||= Fiction.where(component: current_component).find(params[:fiction_id])
      end
    end
  end
end
