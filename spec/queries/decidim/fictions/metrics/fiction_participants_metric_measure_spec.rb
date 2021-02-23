# frozen_string_literal: true

require "spec_helper"

describe Decidim::Fictions::Metrics::FictionParticipantsMetricMeasure do
  let(:day) { Time.zone.yesterday }
  let(:organization) { create(:organization) }
  let(:not_valid_resource) { create(:dummy_resource) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }

  let(:fictions_component) { create(:fiction_component, :published, participatory_space: participatory_space) }
  let!(:fiction) { create(:fiction, :with_endorsements, published_at: day, component: fictions_component) }
  let!(:old_fiction) { create(:fiction, :with_endorsements, published_at: day - 1.week, component: fictions_component) }
  let!(:fiction_votes) { create_list(:fiction_vote, 10, created_at: day, fiction: fiction) }
  let!(:old_fiction_votes) { create_list(:fiction_vote, 5, created_at: day - 1.week, fiction: old_fiction) }
  let!(:fiction_endorsements) do
    5.times.collect do
      create(:endorsement, created_at: day, resource: fiction, author: build(:user, organization: organization))
    end
  end
  # TOTAL Participants for Fictions:
  #  Cumulative: 22 ( 2 fiction, 15 votes, 5 endorsements )
  #  Quantity: 16 ( 1 fiction, 10 votes, 5 endorsements )

  context "when executing class" do
    it "fails to create object with an invalid resource" do
      manager = described_class.new(day, not_valid_resource)

      expect(manager).not_to be_valid
    end

    it "calculates" do
      result = described_class.new(day, fictions_component).calculate

      expect(result[:cumulative_users].count).to eq(22)
      expect(result[:quantity_users].count).to eq(16)
    end

    it "does not found any result for past days" do
      result = described_class.new(day - 1.month, fictions_component).calculate

      expect(result[:cumulative_users].count).to eq(0)
      expect(result[:quantity_users].count).to eq(0)
    end
  end
end
