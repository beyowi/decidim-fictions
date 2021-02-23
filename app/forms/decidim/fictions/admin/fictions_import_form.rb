# frozen_string_literal: true

module Decidim
  module Fictions
    module Admin
      # A form object to be used when admin users want to import a collection of fictions
      # from another component.
      class FictionsImportForm < Decidim::Form
        mimic :fictions_import

        attribute :origin_component_id, Integer
        attribute :import_fictions, Boolean
        attribute :keep_authors, Boolean
        attribute :states, Array

        validates :origin_component_id, :origin_component, :states, :current_component, presence: true
        validates :import_fictions, allow_nil: false, acceptance: true
        validate :valid_states

        VALID_STATES = %w(accepted not_answered evaluating rejected withdrawn).freeze

        def states_collection
          VALID_STATES.map do |state|
            OpenStruct.new(
              name: I18n.t(state, scope: "decidim.fictions.answers"),
              value: state
            )
          end
        end

        def states
          super.reject(&:blank?)
        end

        def origin_component
          @origin_component ||= origin_components.find_by(id: origin_component_id)
        end

        def origin_components
          @origin_components ||= current_participatory_space.components.where.not(id: current_component.id).where(manifest_name: :fictions)
        end

        def origin_components_collection
          origin_components.map do |component|
            [component.name[I18n.locale.to_s], component.id]
          end
        end

        private

        def valid_states
          return if states.all? do |state|
            VALID_STATES.include?(state)
          end

          errors.add(:states, :invalid)
        end
      end
    end
  end
end
