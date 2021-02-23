# frozen-string_literal: true

module Decidim
  module Fictions
    module Admin
      class UpdateFictionCategoryEvent < Decidim::Events::SimpleEvent
        include Decidim::Events::AuthorEvent
      end
    end
  end
end
