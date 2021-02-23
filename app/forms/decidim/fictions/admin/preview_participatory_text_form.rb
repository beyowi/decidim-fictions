# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A form object to be used when admin users want to review a collection of fictions
      # from a participatory text.
      class PreviewParticipatoryTextForm < Decidim::Form
        attribute :fictions, Array[Decidim::Fictions::Admin::ParticipatoryTextFictionForm]

        def from_models(fictions)
          self.fictions = fictions.collect do |fiction|
            Admin::ParticipatoryTextFictionForm.from_model(fiction)
          end
        end

        def fictions_attributes=(attributes); end
      end
    end
  end
end
