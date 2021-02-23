# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A form object to be used when admin users want to create a fiction.
      class FictionForm < Admin::FictionBaseForm
        validates :title, length: { in: 15..150 }
      end
    end
  end
end
