# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    module Admin
      describe ValuationAssignmentForm do
        subject { form }

        let(:organization) { component.participatory_space.organization }
        let(:fictions) { create_list(:fiction, 2, component: component) }
        let(:component) { create(:fiction_component) }
        let(:valuator_process) { component.participatory_space }
        let(:valuator) { create :user, organization: organization }
        let(:valuator_role) { create(:participatory_process_user_role, role: :valuator, user: valuator, participatory_process: valuator_process) }
        let(:params) do
          {
            id: valuator_role.try(:id),
            fiction_ids: fictions.map(&:id)
          }
        end

        let(:form) do
          described_class.from_params(params).with_context(
            current_component: component,
            current_participatory_space: component.participatory_space
          )
        end

        context "when everything is OK" do
          it { is_expected.to be_valid }
        end

        context "without a valuator role" do
          let(:valuator_role) { nil }

          it { is_expected.to be_invalid }
        end

        context "when not enough fictions" do
          let(:fictions) { [] }

          it { is_expected.to be_invalid }
        end

        context "when given a valuator role from another space" do
          let(:valuator_process) { create :participatory_process, organization: organization }

          it { is_expected.to be_invalid }
        end
      end
    end
  end
end
