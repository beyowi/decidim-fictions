# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"
require "decidim/core/test"
require "decidim/core/test/shared_examples/input_sort_examples"

module Decidim
  module Fictions
    describe FictionInputSort, type: :graphql do
      include_context "with a graphql type"

      let(:type_class) { Decidim::Fictions::FictionsType }

      let(:model) { create(:fiction_component) }
      let!(:models) { create_list(:fiction, 3, :published, component: model) }

      context "when sorting by fictions id" do
        include_examples "connection has input sort", "fictions", "id"
      end

      context "when sorting by published_at" do
        include_examples "connection has input sort", "fictions", "publishedAt"
      end

      context "when sorting by endorsement_count" do
        let!(:most_endorsed) { create(:fiction, :published, :with_endorsements, component: model) }

        include_examples "connection has endorsement_count sort", "fictions"
      end

      context "when sorting by vote_count" do
        let!(:votes) { create_list(:fiction_vote, 3, fiction: models.last) }

        describe "ASC" do
          let(:query) { %[{ fictions(order: {voteCount: "ASC"}) { edges { node { id } } } }] }

          it "returns the most voted last" do
            expect(response["fictions"]["edges"].count).to eq(3)
            expect(response["fictions"]["edges"].last["node"]["id"]).to eq(models.last.id.to_s)
          end
        end

        describe "DESC" do
          let(:query) { %[{ fictions(order: {voteCount: "DESC"}) { edges { node { id } } } }] }

          it "returns the most voted first" do
            expect(response["fictions"]["edges"].count).to eq(3)
            expect(response["fictions"]["edges"].first["node"]["id"]).to eq(models.last.id.to_s)
          end
        end
      end
    end
  end
end
