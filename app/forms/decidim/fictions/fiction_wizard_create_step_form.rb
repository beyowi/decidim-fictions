# frozen_string_literal: true

module Decidim
  module Fictions
    # A form object to be used when public users want to create a fiction.
    class FictionWizardCreateStepForm < Decidim::Form
      mimic :fiction

      attribute :title, String
      attribute :body, String
      attribute :body_template, String
      attribute :user_group_id, Integer

      validates :title, :body, presence: true, etiquette: true
      validates :title, length: { in: 15..150 }
      validates :body, fiction_length: {
        minimum: 15,
        maximum: ->(record) { record.component.settings.fiction_length }
      }

      validate :fiction_length
      validate :body_is_not_bare_template

      alias component current_component

      def map_model(model)
        self.user_group_id = model.user_groups.first&.id
        return unless model.categorization

        self.category_id = model.categorization.decidim_category_id
      end

      private

      def fiction_length
        return unless body.presence

        length = current_component.settings.fiction_length
        errors.add(:body, :too_long, count: length) if body.length > length
      end

      def body_is_not_bare_template
        return if body_template.blank?

        errors.add(:body, :cant_be_equal_to_template) if body.presence == body_template.presence
      end
    end
  end
end
