# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A common abstract to be used by the Merge and Split fictions forms.
      class FictionsForkForm < Decidim::Form
        mimic :fictions_import

        attribute :target_component_id, Integer
        attribute :fiction_ids, Array

        validates :target_component, :fictions, :current_component, presence: true
        validate :same_participatory_space
        validate :mergeable_to_same_component

        def fictions
          @fictions ||= Decidim::Fictions::Fiction.where(component: current_component, id: fiction_ids).uniq
        end

        def target_component
          return current_component if clean_target_component_id == current_component.id

          @target_component ||= current_component.siblings.find_by(id: target_component_id)
        end

        def same_component?
          target_component == current_component
        end

        private

        def mergeable_to_same_component
          return true unless same_component?

          public_fictions = fictions.any? do |fiction|
            !fiction.official? || fiction.votes.any? || fiction.endorsements.any?
          end

          errors.add(:fiction_ids, :invalid) if public_fictions
        end

        def same_participatory_space
          return if !target_component || !current_component

          errors.add(:target_component, :invalid) if current_component.participatory_space != target_component.participatory_space
        end

        # Private: Returns the id of the target component.
        #
        # We receive this as ["id"] since it's from a select in a form.
        def clean_target_component_id
          target_component_id.first.to_i
        end
      end
    end
  end
end
