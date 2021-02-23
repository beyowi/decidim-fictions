# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Fictions
    # This cell renders a fictions picker.
    class FictionsPickerCell < Decidim::ViewModel
      MAX_FICTIONS = 1000

      def show
        if filtered?
          render :fictions
        else
          render
        end
      end

      alias component model

      def filtered?
        !search_text.nil?
      end

      def picker_path
        request.path
      end

      def search_text
        params[:q]
      end

      def more_fictions?
        @more_fictions ||= more_fictions_count.positive?
      end

      def more_fictions_count
        @more_fictions_count ||= fictions_count - MAX_FICTIONS
      end

      def fictions_count
        @fictions_count ||= filtered_fictions.count
      end

      def decorated_fictions
        filtered_fictions.limit(MAX_FICTIONS).each do |fiction|
          yield Decidim::Fictions::FictionPresenter.new(fiction)
        end
      end

      def filtered_fictions
        @filtered_fictions ||= if filtered?
                                  fictions.where("title ILIKE ?", "%#{search_text}%")
                                           .or(fictions.where("reference ILIKE ?", "%#{search_text}%"))
                                           .or(fictions.where("id::text ILIKE ?", "%#{search_text}%"))
                                else
                                  fictions
                                end
      end

      def fictions
        @fictions ||= Decidim.find_resource_manifest(:fictions).try(:resource_scope, component)
                       &.published
                       &.order(id: :asc)
      end

      def fictions_collection_name
        Decidim::Fictions::Fiction.model_name.human(count: 2)
      end
    end
  end
end
