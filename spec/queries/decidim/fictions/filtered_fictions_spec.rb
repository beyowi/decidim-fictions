# frozen_string_literal: true

require "spec_helper"

describe Decidim::Fictions::FilteredFictions do
  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, organization: organization) }
  let(:component) { create(:fiction_component, participatory_space: participatory_process) }
  let(:another_component) { create(:fiction_component, participatory_space: participatory_process) }

  let(:fictions) { create_list(:fiction, 3, component: component) }
  let(:old_fictions) { create_list(:fiction, 3, component: component, created_at: 10.days.ago) }
  let(:another_fictions) { create_list(:fiction, 3, component: another_component) }

  it "returns fictions included in a collection of components" do
    expect(described_class.for([component, another_component])).to match_array fictions.concat(old_fictions, another_fictions)
  end

  it "returns fictions created in a date range" do
    expect(described_class.for([component, another_component], 2.weeks.ago, 1.week.ago)).to match_array old_fictions
  end
end
