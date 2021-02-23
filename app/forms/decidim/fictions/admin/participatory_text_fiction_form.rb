# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A form object to be used when admin users want to create a fiction
      # through the participatory texts.
      class ParticipatoryTextFictionForm < Admin::FictionBaseForm
        validates :title, length: { maximum: 150 }
      end
    end
  end
end
