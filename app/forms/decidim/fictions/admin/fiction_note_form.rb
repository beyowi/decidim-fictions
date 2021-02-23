# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A form object to be used when admin users want to create a fiction.
      class FictionNoteForm < Decidim::Form
        mimic :fiction_note

        attribute :body, String

        validates :body, presence: true
      end
    end
  end
end
