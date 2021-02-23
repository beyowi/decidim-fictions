# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    module Admin
      describe FictionsSplitForm do
        subject { form }

        let(:fictions) { create_list(:fiction, 2, component: component) }
        let(:component) { create(:fiction_component) }
        let(:target_component) { create(:fiction_component, participatory_space: component.participatory_space) }
        let(:params) do
          {
            target_component_id: [target_component.try(:id).to_s],
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

        context "without a target component" do
          let(:target_component) { nil }

          it { is_expected.to be_invalid }
        end

        context "when not enough fictions" do
          let(:fictions) { [] }

          it { is_expected.to be_invalid }
        end

        context "when given a target component from another space" do
          let(:target_component) { create(:fiction_component) }

          it { is_expected.to be_invalid }
        end

        context "when merging to the same component" do
          let(:target_component) { component }
          let(:fictions) { create_list(:fiction, 3, :official, component: component) }

          context "when the fiction is not official" do
            let(:fictions) { create_list(:fiction, 3, component: component) }

            it { is_expected.to be_invalid }
          end

          context "when a fiction has a vote" do
            before do
              create(:fiction_vote, fiction: fictions.sample)
            end

            it { is_expected.to be_invalid }
          end

          context "when a fiction has an endorsement" do
            before do
              create(:endorsement, resource: fictions.sample, author: build(:user, organization: component.participatory_space.organization))
            end

            it { is_expected.to be_invalid }
          end
        end
      end
    end
  end
end
