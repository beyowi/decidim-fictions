# frozen_string_literal: true

module Decidim
  module Fictions
    # Class used to retrieve similar fictions.
    class SimilarFictions < Rectify::Query
      include Decidim::TranslationsHelper

      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # components - Decidim::CurrentComponent
      # fiction - Decidim::Fictions::Fiction
      def self.for(components, fiction)
        new(components, fiction).query
      end

      # Initializes the class.
      #
      # components - Decidim::CurrentComponent
      # fiction - Decidim::Fictions::Fiction
      def initialize(components, fiction)
        @components = components
        @fiction = fiction
      end

      # Retrieves similar fictions
      def query
        Decidim::Fictions::Fiction
          .where(component: @components)
          .published
          .where(
            "GREATEST(#{title_similarity}, #{body_similarity}) >= ?",
            @fiction.title,
            @fiction.body,
            Decidim::Fictions.similarity_threshold
          )
          .limit(Decidim::Fictions.similarity_limit)
      end

      private

      def title_similarity
        "similarity(title, ?)"
      end

      def body_similarity
        "similarity(body, ?)"
      end
    end
  end
end
