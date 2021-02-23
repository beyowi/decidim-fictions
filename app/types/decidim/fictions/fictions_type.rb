# frozen_string_literal: true

module Decidim
  module Fictions
    FictionsType = GraphQL::ObjectType.define do
      interfaces [-> { Decidim::Core::ComponentInterface }]

      name "Fictions"
      description "A fictions component of a participatory space."

      connection :fictions,
                 type: FictionType.connection_type,
                 description: "List all fictions",
                 function: FictionListHelper.new(model_class: Fiction)

      field :fiction,
            type: FictionType,
            description: "Finds one fiction",
            function: FictionFinderHelper.new(model_class: Fiction)
    end

    class FictionListHelper < Decidim::Core::ComponentListBase
      argument :order, FictionInputSort, "Provides several methods to order the results"
      argument :filter, FictionInputFilter, "Provides several methods to filter the results"

      # only querying published posts
      def query_scope
        super.published
      end
    end

    class FictionFinderHelper < Decidim::Core::ComponentFinderBase
      argument :id, !types.ID, "The ID of the fiction"

      # only querying published posts
      def query_scope
        super.published
      end
    end
  end
end
