# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A form object to be used when admin users wants to merge two or more
      # fictions into a new one to another fiction component in the same space.
      class FictionsMergeForm < FictionsForkForm
        validates :fictions, length: { minimum: 2 }
      end
    end
  end
end
