# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Fictions
    module Admin
      describe FictionRankingsHelper do
        let(:component) { create(:fiction_component) }

        let!(:fiction1) { create :fiction, component: component, fiction_votes_count: 4 }
        let!(:fiction2) { create :fiction, component: component, fiction_votes_count: 2 }
        let!(:fiction3) { create :fiction, component: component, fiction_votes_count: 2 }
        let!(:fiction4) { create :fiction, component: component, fiction_votes_count: 1 }

        let!(:external_fiction) { create :fiction, fiction_votes_count: 8 }

        describe "ranking_for" do
          it "returns the ranking considering only sibling fictions" do
            result = helper.ranking_for(fiction1, fiction_votes_count: :desc)

            expect(result).to eq(ranking: 1, total: 4)
          end

          it "breaks ties by ordering by ID" do
            result = helper.ranking_for(fiction3, fiction_votes_count: :desc)

            expect(result).to eq(ranking: 3, total: 4)
          end
        end
      end
    end
  end
end
