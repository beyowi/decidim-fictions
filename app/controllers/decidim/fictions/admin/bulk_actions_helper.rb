# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      module BulkActionsHelper
        def fiction_find(id)
          Decidim::Fictions::Fiction.find(id)
        end
      end
    end
  end
end