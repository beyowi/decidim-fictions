# frozen_string_literal: true

module Decidim
  module Fictions
    # A class used to find fictions filtered by components and a date range
    class FilteredFictions < Rectify::Query
      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # components - An array of Decidim::Component
      # start_at - A date to filter resources created after it
      # end_at - A date to filter resources created before it.
      def self.for(components, start_at = nil, end_at = nil)
        new(components, start_at, end_at).query
      end

      # Initializes the class.
      #
      # components - An array of Decidim::Component
      # start_at - A date to filter resources created after it
      # end_at - A date to filter resources created before it.
      def initialize(components, start_at = nil, end_at = nil)
        @components = components
        @start_at = start_at
        @end_at = end_at
      end

      # Finds the Fictions scoped to an array of components and filtered
      # by a range of dates.
      def query
        fictions = Decidim::Fictions::Fiction.where(component: @components)
        fictions = fictions.where("created_at >= ?", @start_at) if @start_at.present?
        fictions = fictions.where("created_at <= ?", @end_at) if @end_at.present?
        fictions
      end
    end
  end
end
